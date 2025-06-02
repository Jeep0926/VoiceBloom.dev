# frozen_string_literal: true

class VoiceConditionLogAnalysisChannel < ApplicationCable::Channel
  def subscribed
    # クライアントから voice_condition_log_id をパラメータで受け取ることを期待
    voice_condition_log = VoiceConditionLog.find_by(id: params[:id])

    # 認証を追加する場合はここで current_user と voice_condition_log.user を比較など
    if voice_condition_log
      stream_from "voice_condition_log_analysis_#{params[:id]}"
    else
      reject # 購読を拒否
    end
  end

  def unsubscribed
    stop_all_streams # 全てのストリームからの購読を停止
  end

  # ★★★ 追加: クライアントからの要求に応じて現在の状態を送信するアクション ★★★
  def request_current_state
    voice_condition_log = find_voice_condition_log
    return log_analysis_not_complete unless analysis_complete?(voice_condition_log)

    transmit_current_state(voice_condition_log)
    log_state_transmitted
  end

  private

  def find_voice_condition_log
    VoiceConditionLog.find_by(id: params[:id])
  end

  def analysis_complete?(voice_condition_log)
    voice_condition_log&.analyzed_at.present? ||
      voice_condition_log&.analysis_error_message.present?
  end

  def transmit_current_state(voice_condition_log)
    html_content = ApplicationController.render(
      partial: 'voice_condition_logs/analysis_result_content',
      locals: { voice_condition_log: voice_condition_log },
      layout: false
    )
    transmit({ html_content: html_content })
  end

  def log_state_transmitted
    Rails.logger.info(
      "Transmitted current state to client for VoiceConditionLog ID #{params[:id]} on request"
    )
  end

  def log_analysis_not_complete
    Rails.logger.info(
      "Current state requested for VoiceConditionLog ID #{params[:id]}, " \
      'but analysis not yet complete or no error.'
    )
  end
end
