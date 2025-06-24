# frozen_string_literal: true

Rails.application.routes.draw do
  mount ActionCable.server => '/cable'
  devise_for :users, controllers: {
    registrations: 'users/registrations', # registrationsコントローラーのパスを指定
    sessions: 'users/sessions'
  }

  # ログイン後のユーザー向けのルートパス
  # ログインしているユーザーが / にアクセスすると Home#index が表示される
  authenticated :user do
    root 'home#index', as: :authenticated_root
  end

  # 未ログインユーザー向けのルートパス (デフォルトのルート)
  # ログインしていないユーザーが / にアクセスすると Statics#top が表示される
  root 'statics#top'

  get 'up' => 'rails/health#show', as: :rails_health_check

  resources :voice_condition_logs, only: %i[new create show]

  resources :practice_session_logs, only: %i[create show] do
    # ER図より、PracticeAttemptLog（試行ログ）は必ず PracticeSessionLog（セッションログ）に属する。
    # 「セッション」を管理する PracticeSessionLog（親） と、「試行」を管理する PracticeAttemptLog（子）は親子関係になる。
    # この関係をURLでも表現するために入れ子にする。
    resources :practice_attempt_logs, only: %i[new create show]
  end

  # ユーザー一人につき学習記録ページは一つなので、単数形リソースとして定義
  resource :learning_log, only: [:show], controller: 'learning_logs'

  # 発声練習メニュー一覧ページ
  resources :practice_menus, only: [:index]
end
