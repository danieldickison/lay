Rails.application.routes.draw do
  get 'tablettes/index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'tablettes/index'
  get 'tablettes/director'
  post 'tablettes/ping'
  post 'tablettes/cue'
  post 'tablettes/preload'

  get 'secrets/index'
  get 'secrets/ping'
  post 'secrets/api_fetch_spectators'
  get 'secrets/gdrive_test'
end
