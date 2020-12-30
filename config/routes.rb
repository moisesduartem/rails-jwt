Rails.application.routes.draw do
  devise_for :users,
  path: 'auth',
  path_names: {
  sign_in: 'login',
  sign_out: 'logout',
  registration: 'register'
  },
  controllers: {
  sessions: 'auth/sessions',
  registrations: 'auth/registrations'
  }  
  
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
