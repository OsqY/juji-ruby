Rails.application.routes.draw do
  get "dashboard", to: "dashboard#index"

  resource :session
  resources :passwords, param: :token
  resources :registrations, only: %i[ new create ]

  resources :daily_reports do
    patch :toggle_blocker, on: :member
  end
  resources :transactions, except: [ :edit, :update ]
  resources :budgets, only: %i[ create destroy ]

  # Root page
  root "dashboard#index"

  # PWA routes
  get "up" => "rails/health#show", as: :rails_health_check
end
