Rails.application.routes.draw do
  root to: 'page#index'
  get '/about' => 'page#about'
end
