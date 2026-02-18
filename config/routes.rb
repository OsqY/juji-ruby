Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :registrations, only: %i[ new create ]

  resources :daily_reports
  resources :transactions, except: [ :edit, :update ]

  # Root page
  root "daily_reports#index"

  # PWA routes
  get "up" => "rails/health#show", as: :rails_health_check
end
