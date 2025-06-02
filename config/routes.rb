# frozen_string_literal: true

Rails.application.routes.draw do
  mount ActionCable.server => '/cable'
  devise_for :users, controllers: {
    registrations: 'users/registrations', # registrationsコントローラーのパスを指定
    sessions: 'users/sessions'
  }
  root 'home#index'
  get 'up' => 'rails/health#show', as: :rails_health_check

  resources :voice_condition_logs, only: %i[new create show]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  # 200 OK を返すだけのヘルスチェック用エンドポイント
  # get '/up', to: proc { [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
  # Defines the root path route ("/")
end
