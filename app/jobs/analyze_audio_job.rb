class AnalyzeAudioJob < ApplicationJob
  queue_as :default

  def perform(voice_condition_log_id)
    voice_condition_log = VoiceConditionLog.find_by(id: voice_condition_log_id)
    unless voice_condition_log
      Rails.logger.warn "AnalyzeAudioJob: VoiceConditionLog with ID #{voice_condition_log_id} not found."
      return
    end

    # 既に分析済み、またはエラーメッセージがあればスキップ（リトライ時など考慮）
    if voice_condition_log.analyzed_at.present? && voice_condition_log.analysis_error_message.blank?
       Rails.logger.info "AnalyzeAudioJob: VoiceConditionLog ID #{voice_condition_log_id} already analyzed."
       return
    end

    Rails.logger.info "AnalyzeAudioJob: Starting analysis for VoiceConditionLog ID #{voice_condition_log_id}."
    service_result = FastApiAnalyzerService.new(voice_condition_log).call

    update_attrs = { analyzed_at: Time.current }
    analysis_completed_successfully = false

    if service_result[:success]
      api_data = service_result[:data]
      update_attrs.merge!(
        pitch_value: api_data[:pitch_value],
        tempo_value: api_data[:tempo_value],
        volume_value: api_data[:volume_value],
        duration_seconds: api_data[:duration_seconds],
        analysis_error_message: api_data[:analysis_error_message] # FastAPI内でのエラー
      )
      analysis_completed_successfully = api_data[:analysis_error_message].blank? # FastAPI内エラーがないか
      Rails.logger.info "AnalyzeAudioJob: Analysis successful for VoiceConditionLog ID #{voice_condition_log_id}."
    else
      update_attrs[:analysis_error_message] = service_result[:error] # 連携自体のエラー
      Rails.logger.error "AnalyzeAudioJob: Analysis failed for VoiceConditionLog ID #{voice_condition_log_id}. Error: #{service_result[:error]}"
    end

    # unless voice_condition_log.update(update_attrs)
    #   Rails.logger.error "AnalyzeAudioJob: Failed to update VoiceConditionLog ID #{voice_condition_log_id}. Errors: #{voice_condition_log.errors.full_messages.join(', ')}"
    # end

    # DB更新試行
    if voice_condition_log.update(update_attrs)
      Rails.logger.info "AnalyzeAudioJob: VoiceConditionLog ID #{voice_condition_log_id} updated in DB."
      # DB更新が成功した場合にブロードキャスト
      broadcast_analysis_update(voice_condition_log)
    else
      Rails.logger.error "AnalyzeAudioJob: Failed to update VoiceConditionLog ID #{voice_condition_log_id}. Errors: #{voice_condition_log.errors.full_messages.join(', ')}"
      # DB更新失敗時もエラー情報をブロードキャストすることを検討 (ここでは省略、必要なら追加)
    end
  end

  private

  def broadcast_analysis_update(voice_condition_log)
    # _analysis_result_content パーシャルをレンダリングしてHTML文字列を取得
    html_content = ApplicationController.render(
      partial: 'voice_condition_logs/analysis_result_content',
      locals: { voice_condition_log: voice_condition_log },
      layout: false
    )
    # 特定のvoice_condition_logのチャネルにブロードキャスト
    ActionCable.server.broadcast(
      "voice_condition_log_analysis_#{voice_condition_log.id}",
      { html_content: html_content } # クライアント側JSが受け取るデータ
    )
    Rails.logger.info "AnalyzeAudioJob: Broadcasted analysis update for VoiceConditionLog ID #{voice_condition_log.id}"
  rescue StandardError => e
    Rails.logger.error "AnalyzeAudioJob: Failed to broadcast update for VoiceConditionLog ID #{voice_condition_log.id}. Error: #{e.message}"
  end
end