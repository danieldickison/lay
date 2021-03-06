Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root 'tablettes#install'

  get 'tablettes/index'
  get 'tablettes/cast'
  get 'tablettes/director'
  post 'tablettes/stats'
  post 'tablettes/ping'
  post 'tablettes/play_timecode'
  post 'tablettes/queue_tablet_command'
  post 'tablettes/set_show_time'
  post 'tablettes/set_current_performance'
  post 'tablettes/start_cue'
  post 'tablettes/stop_cue'
  post 'tablettes/button_a'
  post 'tablettes/button_b'
  post 'tablettes/button_c'
  post 'tablettes/button_d'
  post 'tablettes/button_clear'
  post 'tablettes/assets'
  post 'tablettes/update_patron'

  get 'secrets/index'
  get 'secrets/ping'
  post 'secrets/api_fetch_spectators'
  get 'secrets/gdrive_test'
end
