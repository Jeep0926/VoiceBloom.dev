# frozen_string_literal: true

module Onboarding
  class AttemptsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_onboarding_session
    before_action :set_onboarding_exercises
    before_action :set_current_step
    layout 'task_view'

    def show
      @practice_exercise = @onboarding_exercises[@current_step - 1]
      redirect_to authenticated_root_path, alert: 'オンボーディングのステップが無効です。' and return if @practice_exercise.nil? # rubocop:disable Rails/I18nLocaleTexts

      @practice_attempt_log = @onboarding_session.practice_attempt_logs.build(
        practice_exercise: @practice_exercise,
        attempt_number: @current_step
      )
    end

    def create
      @practice_attempt_log = build_practice_attempt_log
      if @practice_attempt_log.save
        # 保存が成功した場合、JSONレスポンスをレンダリングする
        render_success_response
      else
        # 保存失敗時もJSONでエラーを返す
        render_error_response
      end
    end

    private

    def build_practice_attempt_log
      @onboarding_session.practice_attempt_logs.build(
        practice_attempt_log_params.merge(
          user: current_user,
          attempted_at: Time.current,
          attempt_number: @current_step
        )
      )
    end

    def set_onboarding_session
      # URLの :session_id を使って、現在のユーザーのオンボーディングセッションを取得
      @onboarding_session = current_user.practice_session_logs.onboarding.find(params[:session_id])
    end

    def set_onboarding_exercises
      @onboarding_exercises = PracticeExercise.where(is_for_onboarding: true).order(:id)
    end

    def set_current_step
      @current_step = params[:step].to_i
    end

    def practice_attempt_log_params
      # ビュー側で `practice_attempt_log` にキーを統一したので、こちらも合わせる
      params.require(:practice_attempt_log).permit(:recorded_audio, :practice_exercise_id)
    end

    # 成功時のJSONレスポンスをレンダリングするメソッド
    def render_success_response
      render json: {
        status: 'success',
        # オンボーディングでは個別の評価結果は表示しないため、result_html は空でOK
        result_html: '',
        # 次のアクションを決定する
        next_action: determine_next_step
      }
    end

    # エラー時のJSONレスポンスをレンダリングするメソッド
    def render_error_response
      render json: {
        status: 'error',
        errors: @practice_attempt_log.errors.full_messages
      }, status: :unprocessable_entity
    end

    # 次のアクションを決定するメソッド
    def determine_next_step
      if @current_step < 3
        # 次のステップへリダイレクトするための情報を返す
        next_step_data
      else
        # 3問目が完了した場合のデータを返す
        finish_onboarding_data
      end
    end

    # 次のステップのデータを生成する
    def next_step_data
      next_exercise = @onboarding_exercises[@current_step]
      {
        button_type: 'next',
        # 次のステップの exercise_id も渡す
        url: onboarding_session_attempt_path(@onboarding_session, step: @current_step + 1,
                                                                  exercise_id: next_exercise.id)
      }
    end

    # オンボーディング完了時のデータを生成する
    def finish_onboarding_data
      @onboarding_session.update!(session_ended_at: Time.current)
      current_user.update!(onboarding_status: :completed)

      # TODO: 基準値計算と声キャラ生成の非同期ジョブを呼び出す

      # 今回は、完了したことを示すために「処理中」ページ（仮に学習記録画面）へリダイレクト
      { button_type: 'finish', url: learning_log_path, notice: '録音が完了し、あなたの「声キャラ」の準備が始まりました！' }
    end
  end
end
