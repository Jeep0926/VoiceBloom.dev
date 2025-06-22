# frozen_string_literal: true

class VoiceConditionLogsController < ApplicationController
  before_action :authenticate_user! # ログイン必須にする
  layout 'task_view', only: %i[new show]

  def show
    load_voice_condition_log
    respond_with_log
  end

  def new
    # 新しい VoiceConditionLog オブジェクトを作成 (フォームで使用)
    @voice_condition_log = current_user.voice_condition_logs.build
    # MVPでは固定フレーズを使用
    @fixed_phrase = '今日も一日頑張りましょう！'
  end

  def create
    @voice_condition_log = current_user.voice_condition_logs.build(voice_condition_log_params)
    # Railsが自動で analyzed_at を created_at/updated_at と同じように設定してくれるわけではないので、
    # 明示的に設定する
    # analyzed_at や分析結果フィールドは、ジョブが完了するまで空またはnil
    @voice_condition_log.analyzed_at = nil

    # phrase_text_snapshot は params[:voice_condition_log][:phrase_text_snapshot] から来るはず
    # もしJSから送られていない場合、@fixed_phrase を使うなどのフォールバックも検討できるが、JS側でしっかり送るのが基本。

    if @voice_condition_log.save
      # ここでFastAPIへの連携処理を呼び出す（Active Job を使って非同期でFastAPI連携を実行）
      AnalyzeAudioJob.perform_later(@voice_condition_log.id)
      # 成功した場合、リダイレクト先のURLをJSONで返す
      render json: { status: 'success', redirect_url: voice_condition_log_path(@voice_condition_log) }
    else
      # 失敗した場合、エラーメッセージをJSONで返す
      render json: { status: 'error', errors: @voice_condition_log.errors.full_messages },
             status: :unprocessable_entity
    end
  end

  private

  def load_voice_condition_log
    @voice_condition_log = current_user.voice_condition_logs.find(params[:id])
  end

  # JSONリクエスト用のレスポンスをまとめる
  def respond_with_log
    respond_to do |format|
      format.html
      format.json do
        render json: json_response_data
      end
    end
  end

  def json_response_data
    {
      analyzed_at: @voice_condition_log.analyzed_at,
      error_message: @voice_condition_log.analysis_error_message,
      html_content: render_to_string(
        partial: 'voice_condition_logs/analysis_result_content',
        formats: [:html],
        locals: { voice_condition_log: @voice_condition_log }
      )
    }
  end

  def voice_condition_log_params
    params.require(:voice_condition_log).permit(:recorded_audio, :phrase_text_snapshot)
  end
end
