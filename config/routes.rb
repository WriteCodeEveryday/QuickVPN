Rails.application.routes.draw do
  root to: 'page#index'
  get '/signup' => 'page#signup'
  get '/makemoney' => 'page#makemoney'
  get '/address/:address' => 'page#address'

  post '/generate_credentials' => 'api#generate_credentials'
  post '/stop_credentials' => 'api#stop_credentials'
end
