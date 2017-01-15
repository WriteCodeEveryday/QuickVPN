class PageController < ApplicationController
  include PriceHelper

  def index
  end

  def makemoney
  end

  def signup
    @data = BlockIo.get_new_address
    if @data['status'] == "success"
      @address = @data['data']['address']
      Account.create(public_address: @address, spent_balance: 0, wallet_balance: 0)
      redirect_to "/address/#{@address}"
    end
  end

  def address
    @price = get_price("USD")
    @price_one_min_usd = 0.00019
    @price_one_min_satoshis = ((@price_one_min_usd / @price) * 100000000).to_i

    @address = params['address']
    @account = Account.find_by_public_address(@address)
    if @account
      @account_block = BlockIo.get_address_balance :addresses => "#{@address}"
      if @account_block && @account_block['status'] == "success"
        @account.wallet_balance = (@account_block['data']['available_balance'].to_f * 100000000).to_i
        @account_usage = @account.usages.where(stop_time: nil).first
        @account_usage_past = @account.usages.where.not(stop_time: nil)
        if @account_usage
          @usage = DateTime.now.to_i - @account_usage.start_time.to_i
          @usage_minutes = @usage / 60
          @usage_amount = (@price_one_min_satoshis * @usage_minutes).to_i
          @account.spent_balance += @usage_amount
          @account_usage.amount += @usage_amount
          @account_usage.save
        end
        @account.save
        @current_balance = (@account.wallet_balance - @account.spent_balance) / 100000000.0
        @spent_balance = @account.spent_balance / 100000000.0

        @date = DateTime.now
        @date_estimate = DateTime.now
        @estimated_minutes = (@current_balance * @price) / @price_one_min_usd
        @date_estimate = @date_estimate + (@estimated_minutes / 60)
      else
        redirect_to :root
      end
    else
      redirect_to :root
    end
  end
end
