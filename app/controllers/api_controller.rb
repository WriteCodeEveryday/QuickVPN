class ApiController < ApplicationController
  protect_from_forgery with: :null_session

  def remove_credentials
    @public_address = params['public_address']
    @credentials = Credential.where(public_address: @public_address).first
    @result = {

    }

    # Can only remove inactive accounts.
    if @credentials && @credentials.account_id == nil
      # Find all of the usages.
      @usages = @credentials.usages

      # Remove usages while keeping the id for the account.
      @usages.each do |obj|
        @account = Account.find_by_id(obj.account_id)
        obj.delete

        # Recalculate accounts.
        @account.spent_balance = @account.usages.sum(:amount)
        @account.save
      end

      # Remove credentials.
      @credentials.delete

      @result['status'] = "success"
      @result['data'] = "Account successfully purged."
      @result['code'] = 200
    else
      @result['status'] = "error"
      @result['data'] = "Error: Incorrect Address"
      @result['code'] = 404
    end

    render json: @result
  end

  def get_balance
    @public_address = params['public_address']
    @credentials = Credential.where(public_address: @public_address).first
    @result = {

    }

    # Only process if that address exists.
    if @credentials
      @btc = "%f" % (@credentials.usages.sum(:amount) / 100000000.0)
      @result['status'] = "success"
      @result['data'] = "Balance: #{@btc} BTC"
      @result['code'] = 200
    else
      @result['status'] = "error"
      @result['message'] = "Error: Incorrect Address"
      @result['code'] = 404
    end

    render json: @result
  end

  def add_credentials
    @username = params['username']
    @password = params['password']
    @public_address = params['public_address']
    @result = {

    }

    @vpnUser = @username
    @vpnPassword = @password
    a = Mechanize.new { |agent|
      # Allow rerfresh
      agent.follow_meta_refresh = true
    }

    a.get('https://www.privateinternetaccess.com/pages/client-sign-in') do |signin_page|
      my_page = signin_page.form_with(:class=>'signin__form') do |form|
        #User form field names
        form.user = @vpnUser
        form.pass = @vpnPassword
      end.submit

      if my_page.uri.path == "/pages/client-control-panel"
        @creds = Credential.new(secret: "#{@username}:#{@password}", public_address: @public_address, account_id: nil)
        @creds.save!

        @result['status'] = "success"
        @result['data'] = "Storage Complete"
        @result['code'] = 200
      else
        @result['status'] = "error"
        @result['message'] = "Error: Credentials incorrect"
        @result['code'] = 404
      end

      render json: @result
    end
  end

  def withdraw_change
    @address = params['address']
    @account = Account.find_by_public_address(@address)
    @credential = @account.credential
    @result = {

    }

    #XXX Verify that it's not involved in ongoing operations
    if @account && !@credential
      @to_addresses = ""
      @amount = ""

      #XXX Pay out 'credentials' for each usage
      @to_addresses = Credential.where(id: @account.usages.pluck(:credential_id)).pluck(:public_address).join(",")
      @from_addresses = @account.public_address
      @amount = @account.usages.pluck(:amount).map { |n| (n / 100000000.0) * 0.7 }.join(",")


      #XXX Pay out remainder to original deposit address.
      @incoming_tx = BlockIo.get_transactions :type => 'received', :addresses => "#{@account.public_address}"
      @incoming_address = @incoming_tx['data']['txs'][0]['senders'][0]
      @to_addresses += ",#{@incoming_address}"
      @temp_amount = ((@account.wallet_balance - @account.spent_balance) / 100000000.0)

      #XXX Estimate out fees and substract from the VPN client fees.
      @fees = BlockIo.get_network_fee_estimate :amounts => "#{@amount},#{@temp_amount}", :to_addresses => @to_addresses
      @fees = @fees['data']['estimated_network_fee'].to_f
      @amount += ",#{@temp_amount - @fees}"

      @transfer = BlockIo.withdraw :amounts => @amount, :to_addresses => @to_addresses, :from_addresses => @from_addresses, :pin => ENV['BLOCK_PIN']
      if @transfer['status'] == "success"
        @account.delete
        @result['status'] = "success"
        @result['data'] = "TX Hash: #{@transfer['data']['txid']}"
        @result['code'] = 200
      else
        @result['status'] = "error"
        @result['message'] = "TX Hash: #{@transfer['data']['message']}"
        @result['code'] = 200
      end
      # {
      #   "status" : "success",
      #   "data" : {
      #     "network" : "BTCTEST",
      #     "txid" : "59119b6e41822023786fa516296636534cbc87884248d01a65bc1a78fad75b7b",
      #     "amount_withdrawn" : "0.01000000",
      #     "amount_sent" : "0.00980000",
      #     "network_fee" : "0.00020000",
      #     "blockio_fee" : "0.00000000"
      #   }
      # } - Success Outcome.

      # {
      #   "status" : "fail",
      #   "data" : {
      #     "error_message" : "Cannot withdraw funds without Network Fee of 0.00000 BTCTEST. Maximum withdrawable balance is 0.00000 BTCTEST.",
      #     "available_balance" : "0.00000000",
      #     "max_withdrawal_available" : "0.00000000",
      #     "minimum_balance_needed" : "0.00980000",
      #     "estimated_network_fee" : "0.00000000"
      #   }
      # } - Failure Outcome.
    else
      @result['status'] = "error"
      @result['message'] = "Account in use. Cannot withdraw."
      @result['code'] = 400
    end

    render json: @result
  end

  def stop_credentials
    @address = params['address']
    @account = Account.find_by_public_address(@address)
    @credential = @account.credential
    @usage = @account.usages.where(stop_time: nil).first
    @result = {

    }

    if @account && @credential && @usage
      #Get the last updated amount
      HTTParty.get("http://#{request.host}/address/#{@address}")

      #Update the last usage time.
      @usage.stop_time = DateTime.now
      @usage.save

      #Clear credentials.
      @credential.username = ""
      @credential.password = ""
      @credential.account_id = nil
      @credential.save

      #Reset password just to be sure.
      @vpnUser = @credential.secret.split(":")[0]
      @vpnPassword = @credential.secret.split(":")[1]
      a = Mechanize.new { |agent|
      	# Allow rerfresh
      	agent.follow_meta_refresh = true
      }

      #Login, reset and go
      a.get('https://www.privateinternetaccess.com/pages/client-sign-in') do |signin_page|
      	my_page = signin_page.form_with(:class=>'signin__form') do |form|
      		#User form field names
      		form.user = @vpnUser
      		form.pass = @vpnPassword
      	end.submit

      	#Find the reset credential form.
      	my_page = my_page.form_with(:action=>'https://www.privateinternetaccess.com/pages/ccp-gen-x-password') do |regen_form|
      		#Just reset the password.
      	end.submit
      end

      @result['status'] = "success"
      @result['data'] = "Thank you for your patronage."
      @result['code'] = 200
    else
      @result['status'] = "error"
      @result['message'] = "Error: Could Not Close Connection (This Should Not Happen)"
      @result['code'] = 404
    end

    render json: @result
  end

  def generate_credentials
    @address = params['address']
    @account = Account.find_by_public_address(@address)
    @credential = Credential.where(account_id: nil).order("RANDOM()").first
    @result = {

    }

    if @account && @account.wallet_balance > 0 && @credential
      #OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
      #I_KNOW_THAT_OPENSSL_VERIFY_PEER_EQUALS_VERIFY_NONE_IS_WRONG = nil

      @vpnUser = @credential.secret.split(":")[0]
      @vpnPassword = @credential.secret.split(":")[1]
      a = Mechanize.new { |agent|
      	# Allow rerfresh
      	agent.follow_meta_refresh = true
      }

      a.get('https://www.privateinternetaccess.com/pages/client-sign-in') do |signin_page|
      	my_page = signin_page.form_with(:class=>'signin__form') do |form|
      		#User form field names
      		form.user = @vpnUser
      		form.pass = @vpnPassword
      	end.submit
      	#puts my_page.uri

      	#Find the reset credential form.
      	my_page = my_page.form_with(:action=>'https://www.privateinternetaccess.com/pages/ccp-gen-x-password') do |regen_form|
      		#Find the value for user name.
      		#Find the value for password.
      	end.submit

        #Save username/password
      	values = []
      	parsed_page = Nokogiri::HTML(my_page.body)
      	parsed_page.css('form').css('p').css('strong').map do |a|
      		values.push(a.inner_html)
      	end

        #Begin a usage period.
        @usage = Usage.new(start_time: DateTime.now, account_id: @account.id, credential_id: @credential.id, amount: 0)
        @usage.save

        #Assign credentials to specific account.
        @credential.account_id = @account.id
        @credential.username = values[0]
        @credential.password = values[1]
        @credential.save

        @result['status'] = "success"
        @result['data'] = values
        @result['code'] = 200
      end
    elsif @account && @account.wallet_balance == 0
      @result['status'] = "error"
      @result['message'] = "Error: No Bitcoin Available"
      @result['code'] = 404
    elsif @account
      @result['status'] = "error"
      @result['message'] = "Error: No Available VPN Account"
      @result['code'] = 404
    else
      @result['status'] = "error"
      @result['message'] = "Error: Invalid Address"
      @result['code'] = 404
    end

    render json: @result
  end
end
