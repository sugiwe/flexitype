Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication routes
  post "/auth/google", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  # Public pages
  root "home#index"
  resources :practices, only: [ :show ]
  get "about", to: "pages#about"
  get "terms", to: "pages#terms"
  get "privacy", to: "pages#privacy"

  # User profiles (public)
  get "/@:username", to: "profiles#show", as: :profile, constraints: { username: /[^\/]+/ }

  # Personal pages (authentication required, /my namespace)
  namespace :my do
    root to: "dashboard#index"  # /my
    resources :keymaps, only: [ :index, :new, :create, :edit, :update, :destroy ], param: :slug  # /my/keymaps, /my/keymaps/new, POST /my/keymaps, /my/keymaps/keymap-1/edit, PATCH /my/keymaps/keymap-1, DELETE /my/keymaps/keymap-1
    resources :history, only: [ :index, :create ]  # /my/history, POST /my/history
    resource :account, only: [ :edit, :update ]  # /my/account/edit, PATCH /my/account
  end

  # Admin pages (authentication + admin permission required, /admin namespace)
  namespace :admin do
    root to: "dashboard#index"  # /admin
    resources :users, only: [ :index, :show ]  # /admin/users, /admin/users/:id
  end
end
