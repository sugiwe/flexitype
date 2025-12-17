Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Authentication routes
  post "/auth/google", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  # Public pages
  root "home#index"
  resources :practices, only: [ :show ]
  get "terms", to: "pages#terms"
  get "privacy", to: "pages#privacy"

  # User profiles (public)
  get "/@:username", to: "profiles#show", as: :profile, constraints: { username: /[^\/]+/ }

  # Personal pages (authentication required, /my namespace)
  namespace :my do
    root to: "dashboard#index"  # /my
    resources :keymaps, only: [ :index, :edit, :update ]  # /my/keymaps, /my/keymaps/1/edit, PATCH /my/keymaps/1
    resources :history, only: [ :index, :create ]  # /my/history, POST /my/history
    resource :account, only: [ :edit, :update ]  # /my/account/edit, PATCH /my/account
  end
end
