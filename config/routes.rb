Rails.application.routes.draw do
  root to: 'page#index'
  get '/signup' => 'page#signup'
  get '/profit' => 'page#makemoney'
  get '/profit/settings' => 'page#makemoneysettings'
  get '/address/:address' => 'page#address'

  post '/generate_credentials' => 'api#generate_credentials'
  post '/stop_credentials' => 'api#stop_credentials'
  post '/withdraw_change' => 'api#withdraw_change'

  post '/add_credentials' => 'api#add_credentials'
  post '/get_balance' => 'api#get_balance'
  post '/remove_credentials' => 'api#remove_credentials'
end
