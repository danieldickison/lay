Rails.application.routes.draw do
  get 'tablettes/index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'tablettes/index'
  get 'tablettes/director'
  post 'tablettes/ping'
  post 'tablettes/cue'

  get 'secrets/index'
  post 'secrets/fetch_spectators'
end
