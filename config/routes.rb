Rails.application.routes.draw do
  get "dashboard", to: "dashboard#index"
  get "guide", to: "guides#show"
  
  # Search routes
  get "search", to: "search#index", as: :search
  get "search/results", to: "search#results", as: :search_results

  # Export routes
  post "exports", to: "exports#create", as: :exports

  # Push notification routes
  post "push_notifications/register", to: "push_notifications#register"
  delete "push_notifications/unregister", to: "push_notifications#unregister"

  # Analytics routes
  get "analytics", to: "analytics#index", as: :analytics
  get "analytics/data/:metric", to: "analytics#data", as: :analytics_data

  resource :session
  namespace :sessions do
    resource :validate, only: [:show], controller: "validate"
  end
  resources :passwords, param: :token
  resources :registrations, only: %i[ new create ]

  resources :daily_reports do
    patch :toggle_blocker, on: :member
  end
  resources :transactions, except: [ :edit, :update ]
  resources :budgets, only: %i[ index create destroy ]
  resources :projects, only: %i[ index create destroy ] do
    resources :project_tasks, only: %i[ create destroy ] do
      post :toggle, on: :member
    end
  end
  resources :habits, only: %i[ index create destroy ] do
    post :toggle, on: :member
  end
  resources :shopping_items, only: %i[ index create update destroy ]
  resources :notifications, only: %i[ index ] do
    patch :mark_as_read, on: :member
    patch :mark_all_as_read, on: :collection
  end
  resources :anonymous_forms, only: %i[ index new create show destroy ]
  resources :whiteboards, only: %i[ index new create show destroy ]
  resources :monthly_goals, except: %i[ show ] do
    member do
      post :check_progress
    end
  end

  resources :chat_rooms, path: "salas" do
    member do
      post :join
      post :leave
      post :invite
      delete :kick
    end
    resources :messages, only: [:create], module: :chat_rooms
  end

  resources :friends, only: [:index, :destroy] do
    collection do
      get :pending
      post :accept
      post :reject
    end
  end

  scope "/c/:token", as: :public_chat_room do
    get "/", to: "chat_rooms#public_show"
    post "/join", to: "chat_rooms#public_join"
  end

  get "/friends/accept/:token", to: "friends#accept_invitation", as: :friend_invitation
  get "/invite/:token", to: "friends#accept_user_invite", as: :user_invite

  scope "/w/:token", as: :public_whiteboard do
    get "/", to: "whiteboards#public_show"
  end

  scope "/f/:token", as: :public_anonymous_form do
    get "/", to: "public_anonymous_forms#show"
    post "/responses", to: "public_anonymous_forms#create_response", as: :responses
  end

  # Root page
  root "dashboard#index"

  # PWA routes
  get "up" => "rails/health#show", as: :rails_health_check
end
