# frozen_string_literal: true

# オンボーディングセッションを開始するためのコントローラー
module Onboarding
  class SessionsController < ApplicationController
    before_action :authenticate_user!
    before_action :redirect_if_completed, only: [:create]

    # POST /onboarding/sessions
    def create
      session = setup_onboarding_session
      redirect_to_onboarding_or_root(session)
    end

    private

    def redirect_if_completed
      # 既に完了しているユーザーはホームへリダイレクト
      return unless current_user.completed?

      redirect_to authenticated_root_path, notice: 'あなたの「声キャラ」はすでに作成されています。' # rubocop:disable Rails/I18nLocaleTexts
    end

    def setup_onboarding_session
      # オンボーディング用の新しい練習セッションを作成
      session = current_user.practice_session_logs.create!(
        session_started_at: Time.current,
        session_type: :onboarding # セッションタイプを 'onboarding' に設定
      )
      current_user.update!(onboarding_status: :in_progress)
      session
    end

    def redirect_to_onboarding_or_root(session)
      # オンボーディング用の最初のお題を取得
      first_exercise = PracticeExercise.where(is_for_onboarding: true).order(:id).first

      if first_exercise
        # 最初の練習画面へリダイレクト
        # 「config/routes.rb」でネストされたルートに対応
        redirect_to onboarding_session_attempt_path(session, step: 1)
      else
        redirect_to authenticated_root_path, alert: 'オンボーディングを開始できませんでした。' # rubocop:disable Rails/I18nLocaleTexts
      end
    end
  end
end
