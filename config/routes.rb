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
  resources :notifications do
    patch :mark_as_read, on: :member
    patch :mark_all_as_read, on: :collection
  end
  resources :anonymous_forms, only: %i[ index new create show destroy ]

  scope "/f/:token", as: :public_anonymous_form do
    get "/", to: "public_anonymous_forms#show"
    post "/responses", to: "public_anonymous_forms#create_response", as: :responses
  end

  # Root page
  root "dashboard#index"

  # PWA routes
  get "up" => "rails/health#show", as: :rails_health_check
end
