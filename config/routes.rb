Rails.application.routes.draw do
  # Devise
  devise_for :users

  # Root
  root "home#top"
  get "about", to: "home#about"

  # Books
  resources :books do
    resource :favorite, only: [:create, :destroy]
    resource :bookmark, only: [:create, :destroy]
    resources :book_comments, only: [:create, :destroy]
    resource :rating, only: [:create, :update]
  end

  # Users
  resources :users, only: [:index, :show, :edit, :update] do
    member do
      get :followers
      get :following
    end
    resource :relationship, only: [:create, :destroy]
  end

  # Bookmarks
  resources :bookmarks, only: [:index]

  # Notifications
  resources :notifications, only: [:index] do
    member do
      patch :mark_as_read
    end
    collection do
      post :mark_all_as_read
    end
  end

  # Search
  get "search", to: "search#index"

  # Health check
  get "up", to: "rails/health#show", as: :rails_health_check
end
