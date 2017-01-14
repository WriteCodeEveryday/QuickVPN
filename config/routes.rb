Rails.application.routes.draw do
  root to: 'page#index'
  get '/signup' => 'page#signup'
  get '/makemoney' => 'page#makemoney'
end
