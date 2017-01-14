require 'rubygems'
require 'mechanize'
require 'Nokogiri'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
I_KNOW_THAT_OPENSSL_VERIFY_PEER_EQUALS_VERIFY_NONE_IS_WRONG = nil

vpnUser = ""
vpnPassword = ""
a = Mechanize.new { |agent| 
	# Allow rerfresh
	agent.follow_meta_refresh = true
}

a.get('https://www.privateinternetaccess.com/pages/client-sign-in') do |signin_page|
	my_page = signin_page.form_with(:class=>'signin__form') do |form|
		#User form field names
		form.user = vpnUser
		form.pass = vpnPassword
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
	
	# Prints the result.
	#puts values
	
end	