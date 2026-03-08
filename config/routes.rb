Rails.application.routes.draw do
  get "dashboard", to: "dashboard#index"
  get "guide", to: "guides#show"

  resource :session
  resources :passwords, param: :token
  resources :registrations, only: %i[ new create ]

  resources :daily_reports do
    patch :toggle_blocker, on: :member
  end
  resources :transactions, except: [ :edit, :update ]
  resources :budgets
  resources :projects do
    resources :project_tasks do
      post :toggle, on: :member
    end
  end
  resources :habits do
    post :toggle, on: :member
  end
  resources :shopping_items

  # Root page
  root "dashboard#index"

  # PWA routes
  get "up" => "rails/health#show", as: :rails_health_check
end
