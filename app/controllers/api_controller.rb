class ApiController < ApplicationController
  protect_from_forgery with: :null_session

  def generate_credentials
    @address = params['address']
    @account = Account.find_by_public_address(@address)
    @credential = Credential.where(account_id: nil).first
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

      	values = []
      	parsed_page = Nokogiri::HTML(my_page.body)
      	parsed_page.css('form').css('p').css('strong').map do |a|
      		values.push(a.inner_html)
      	end

        @usage = Usage.new(start_time: DateTime.now, account_id: @account.id, credential_id: @credential.id)
        @usage.save!

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