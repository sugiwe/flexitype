Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication routes
  post "/auth/google", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  # Development-only authentication bypass
  if Rails.env.development?
    namespace :dev do
      get "sessions", to: "sessions#index"
      post "sessions", to: "sessions#create"
      delete "sessions", to: "sessions#destroy"
    end
  end

  # Test-only session management
  if Rails.env.test?
    post "/test/sessions", to: "test_sessions#create"
    delete "/test/sessions", to: "test_sessions#destroy"
  end

  # Public pages
  root "home#index"
  resources :lessons, only: [ :show ]

  # 旧URLからのリダイレクト（301 Moved Permanently）
  get "/practices/:id", to: redirect("/lessons/%{id}", status: 301)

  # Share pages (public)
  resources :shares, only: [ :show, :create ], param: :token

  get "about", to: "pages#about"
  get "terms", to: "pages#terms"
  get "privacy", to: "pages#privacy"

  # User profiles (public)
  get "/@:username", to: "profiles#show", as: :profile, constraints: { username: /[^\/]+/ }

  # Personal pages (authentication required, /my namespace)
  namespace :my do
    root to: "dashboard#index"  # /my
    resources :keymaps, only: [ :index, :new, :create, :edit, :update, :destroy ], param: :slug
    resources :lessons, only: [ :index, :new, :create, :edit, :update, :destroy ]  # /my/lessons (公式レッスン + 自作レッスン + 公開レッスン管理)
    resources :history, only: [ :index, :create ]  # /my/history, POST /my/history
    resource :account, only: [ :edit, :update ]  # /my/account/edit, PATCH /my/account
  end

  # Admin pages (authentication + admin permission required, /admin namespace)
  namespace :admin do
    root to: "dashboard#index"  # /admin
    resources :users, only: [ :index, :show ]  # /admin/users, /admin/users/:id
    resources :categories, except: [ :show ]  # /admin/categories (CRUD, show不要)
  end
end
