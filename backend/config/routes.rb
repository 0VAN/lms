# frozen_string_literal: true

Rails.application.routes.draw do
  post '/register', to: 'registrations#create'
  post '/login', to: 'sessions#create'
  post '/logout', to: 'sessions#destroy'

  resources :books do
    member do
      post :borrow, to: 'borrowings#create'
    end
  end

  resources :borrowings, only: [] do
    member do
      post :return, to: 'borrowings#return_book'
    end
  end

  get '/borrowings', to: 'borrowings#index'
  get '/dashboard', to: 'dashboards#show'
  get '/health', to: 'health#show'
end
