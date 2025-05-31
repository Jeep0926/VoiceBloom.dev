# frozen_string_literal: true

class VoiceConditionLogAnalysisChannel < ApplicationCable::Channel
  def subscribed
    # クライアントから voice_condition_log_id をパラメータで受け取ることを期待
    voice_condition_log = VoiceConditionLog.find_by(id: params[:id])

    # 認証を追加する場合はここで current_user と voice_condition_log.user を比較など
    if voice_condition_log
      stream_from "voice_condition_log_analysis_#{params[:id]}"
      Rails.logger.info "Client subscribed to VoiceConditionLogAnalysisChannel for ID #{params[:id]}"
    else
      reject # 購読を拒否
      Rails.logger.warn(
        "Client failed to subscribe: VoiceConditionLog with ID #{params[:id]} not found or unauthorized."
      )
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams # 全てのストリームからの購読を停止
    Rails.logger.info "Client unsubscribed from VoiceConditionLogAnalysisChannel (was streaming for ID #{params[:id]})"
  end
end
