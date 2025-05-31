# frozen_string_literal: true

class AnalyzeAudioJob < ApplicationJob
  queue_as :default

  def perform(voice_condition_log_id)
    voice_condition_log = find_voice_condition_log(voice_condition_log_id)
    return unless voice_condition_log

    return if already_analyzed?(voice_condition_log, voice_condition_log_id)

    process_analysis(voice_condition_log, voice_condition_log_id)
  end

  private

  def find_voice_condition_log(voice_condition_log_id)
    VoiceConditionLog.find_by(id: voice_condition_log_id).tap do |log|
      log_not_found_warning(voice_condition_log_id) unless log
    end
  end

  def log_not_found_warning(voice_condition_log_id)
    Rails.logger.warn(
      "AnalyzeAudioJob: VoiceConditionLog with ID #{voice_condition_log_id} not found."
    )
  end

  def already_analyzed?(voice_condition_log, voice_condition_log_id)
    return false unless voice_condition_log.analyzed_at.present? &&
                        voice_condition_log.analysis_error_message.blank?

    log_already_analyzed(voice_condition_log_id)
    true
  end

  def log_already_analyzed(voice_condition_log_id)
    Rails.logger.info(
      "AnalyzeAudioJob: VoiceConditionLog ID #{voice_condition_log_id} already analyzed."
    )
  end

  def process_analysis(voice_condition_log, voice_condition_log_id)
    log_analysis_start(voice_condition_log_id)

    service_result = FastApiAnalyzerService.new(voice_condition_log).call
    updater = AnalysisResultUpdater.new(voice_condition_log, voice_condition_log_id)
    updater.update_with_result(service_result)
  end

  def log_analysis_start(voice_condition_log_id)
    Rails.logger.info(
      "AnalyzeAudioJob: Starting analysis for VoiceConditionLog ID #{voice_condition_log_id}."
    )
  end

  # 内部クラスで更新処理とブロードキャスト処理を分離
  class AnalysisResultUpdater
    def initialize(voice_condition_log, voice_condition_log_id)
      @voice_condition_log = voice_condition_log
      @voice_condition_log_id = voice_condition_log_id
    end

    def update_with_result(service_result)
      update_attrs = build_update_attributes(service_result)
      perform_update(update_attrs)
    end

    private

    def build_update_attributes(service_result)
      update_attrs = { analyzed_at: Time.current }

      if service_result[:success]
        merge_successful_data(service_result, update_attrs)
      else
        handle_failed_analysis(service_result, update_attrs)
      end

      update_attrs
    end

    def merge_successful_data(service_result, update_attrs)
      api_data = service_result[:data]
      update_attrs.merge!(extract_analysis_data(api_data))
      log_success
    end

    def extract_analysis_data(api_data)
      {
        pitch_value: api_data[:pitch_value],
        tempo_value: api_data[:tempo_value],
        volume_value: api_data[:volume_value],
        duration_seconds: api_data[:duration_seconds],
        analysis_error_message: api_data[:analysis_error_message]
      }
    end

    def handle_failed_analysis(service_result, update_attrs)
      update_attrs[:analysis_error_message] = service_result[:error]
      log_failure(service_result[:error])
    end

    def perform_update(update_attrs)
      if @voice_condition_log.update(update_attrs)
        handle_successful_update
      else
        handle_failed_update
      end
    end

    def handle_successful_update
      log_update_success
      AnalysisBroadcaster.new(@voice_condition_log).broadcast
    end

    def handle_failed_update
      Rails.logger.error(
        "AnalyzeAudioJob: Failed to update VoiceConditionLog ID #{@voice_condition_log_id}. " \
        "Errors: #{@voice_condition_log.errors.full_messages.join(', ')}"
      )
    end

    def log_success
      Rails.logger.info(
        "AnalyzeAudioJob: Analysis successful for VoiceConditionLog ID #{@voice_condition_log_id}."
      )
    end

    def log_failure(error)
      Rails.logger.error(
        "AnalyzeAudioJob: Analysis failed for VoiceConditionLog ID #{@voice_condition_log_id}. " \
        "Error: #{error}"
      )
    end

    def log_update_success
      Rails.logger.info(
        "AnalyzeAudioJob: VoiceConditionLog ID #{@voice_condition_log_id} updated in DB."
      )
    end
  end

  # ブロードキャスト処理を分離
  class AnalysisBroadcaster
    def initialize(voice_condition_log)
      @voice_condition_log = voice_condition_log
    end

    def broadcast
      html_content = render_analysis_result
      send_broadcast(html_content)
      log_success
    rescue StandardError => e
      log_failure(e)
    end

    private

    def render_analysis_result
      ApplicationController.render(
        partial: 'voice_condition_logs/analysis_result_content',
        locals: { voice_condition_log: @voice_condition_log },
        layout: false
      )
    end

    def send_broadcast(html_content)
      ActionCable.server.broadcast(
        "voice_condition_log_analysis_#{@voice_condition_log.id}",
        { html_content: html_content }
      )
    end

    def log_success
      Rails.logger.info(
        "AnalyzeAudioJob: Broadcasted analysis update for VoiceConditionLog ID #{@voice_condition_log.id}"
      )
    end

    def log_failure(error)
      Rails.logger.error(
        "AnalyzeAudioJob: Failed to broadcast update for VoiceConditionLog ID #{@voice_condition_log.id}. " \
        "Error: #{error.message}"
      )
    end
  end
end
