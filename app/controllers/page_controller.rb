class PageController < ApplicationController
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


    @address = params['address']
    @account = Account.find_by_public_address(@address)
    if @account
      @account_block = BlockIo.get_address_balance :addresses => "#{@address}"
      if @account_block && @account_block['status'] == "success"
        @account.wallet_balance = (@account_block['data']['available_balance'].to_f * 100000000).to_i
        @account.save
        @current_balance = (@account.wallet_balance - @account.spent_balance) / 100000000.0
        @spent_balance = @account.spent_balance / 100000000.0
      else
        redirect_to :root
      end
    else
      redirect_to :root
    end
  end
end
