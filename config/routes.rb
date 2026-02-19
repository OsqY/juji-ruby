Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :registrations, only: %i[ new create ]

  resources :daily_reports
  resources :transactions, except: [ :edit, :update ]
  resources :shopping_items, only: %i[ index create update destroy ]
  resources :habits, only: %i[ index create destroy ] do
    member do
      post :toggle
    end
  end

  resources :projects, only: %i[ index create destroy ] do
    resources :project_tasks, only: %i[ create destroy ] do
      member do
        post :toggle
      end
    end
  end

  # Root page
  root "daily_reports#index"

  # PWA routes
  get "up" => "rails/health#show", as: :rails_health_check
end
