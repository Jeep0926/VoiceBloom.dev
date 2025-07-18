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

      # ビューでフォームの情報を表示するために、未保存のオブジェクトを準備
      @voice_condition_log = @onboarding_session.voice_condition_logs.build
      # プログレスバー表示のため、ダミーの attempt_number を設定
      @dummy_attempt_number = @current_step
    end

    def create
      @voice_condition_log = build_voice_condition_log

      if @voice_condition_log.save
        # 保存成功後、バックグラウンドで音声分析ジョブが自動的に実行される
        render_success
      else
        render_error
      end
    end

    private

    def build_voice_condition_log
      @onboarding_session.voice_condition_logs.build(
        voice_condition_log_params.merge(user: current_user)
      )
    end

    def render_success
      render json: { status: 'success', next_action: determine_next_step }
    end

    def render_error
      render json: { status: 'error', errors: @voice_condition_log.errors.full_messages },
             status: :unprocessable_entity
    end

    def set_onboarding_session
      @onboarding_session = current_user.practice_session_logs.onboarding.find(params[:session_id])
    end

    def set_onboarding_exercises
      @onboarding_exercises = PracticeExercise.where(is_for_onboarding: true).order(:id)
    end

    def set_current_step
      @current_step = params[:step].to_i
    end

    def voice_condition_log_params
      # `practice_exercise_id` は直接使わないが、お題のテキストをスナップショットとして保存
      exercise = PracticeExercise.find(params[:voice_condition_log][:practice_exercise_id])
      params.require(:voice_condition_log)
            .permit(:recorded_audio)
            .merge(phrase_text_snapshot: exercise.text_content)
    end

    def determine_next_step
      on_final_step? ? finish_onboarding_and_get_next_step : prepare_next_step
    end

    def on_final_step?
      @current_step >= 3
    end

    def prepare_next_step
      next_exercise = @onboarding_exercises[@current_step]
      {
        button_type: 'next',
        url: onboarding_session_attempt_path(
          @onboarding_session,
          step: @current_step + 1,
          exercise_id: next_exercise.id
        )
      }
    end

    def finish_onboarding_and_get_next_step
      @onboarding_session.update!(session_ended_at: Time.current)
      current_user.update!(onboarding_status: :completed)

      # 基準値計算ジョブを呼び出す
      BaselineCalculationJob.perform_later(current_user.id)

      # 将来の「処理中」ページへのリダイレクト情報を返す
      # 今の段階では、仮で学習記録画面へ
      {
        button_type: 'finish',
        url: learning_log_path,
        notice: 'オンボーディングが完了し、あなたの「声キャラ」の準備が始まりました！'
      }
    end
  end
end
