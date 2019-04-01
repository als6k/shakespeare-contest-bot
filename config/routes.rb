Rails.application.routes.draw do
  post '/quiz', to: 'search#quiz'
  root 'logs#index'
end
