# frozen_string_literal: true

require 'faraday'
require 'faraday/multipart'

class FastApiAnalyzerService
  FASTAPI_URL = ENV.fetch('FASTAPI_URL', 'http://api:8000')
  ANALYZE_PATH = '/analyze/voice_condition'

  def initialize(voice_condition_log)
    @voice_condition_log = voice_condition_log
    @audio_blob = @voice_condition_log.recorded_audio.blob
  end

  def call
    return { success: false, error: 'Audio file not attached or found.' } unless @audio_blob

    connection = build_faraday_connection
    send_analysis_request(connection)
  rescue StandardError => e
    handle_unexpected_error(e)
  end

  private

  def build_faraday_connection
    Faraday.new(url: FASTAPI_URL) do |faraday|
      faraday.request :multipart
      faraday.request :url_encoded
      faraday.adapter Faraday.default_adapter
      faraday.options.timeout = 60
      faraday.options.open_timeout = 30
    end
  end

  def send_analysis_request(connection)
    @audio_blob.open do |tempfile|
      payload = build_request_payload(tempfile)
      response = connection.post(ANALYZE_PATH, payload)
      process_response(response)
    end
  rescue Faraday::Error => e
    handle_faraday_error(e)
  rescue JSON::ParserError => e
    handle_json_parse_error(e)
  end

  def build_request_payload(tempfile)
    {
      file: Faraday::Multipart::FilePart.new(
        tempfile.path,
        @audio_blob.content_type,
        @audio_blob.filename.to_s
      )
    }
  end

  def process_response(response)
    if response.success?
      parsed_response = JSON.parse(response.body, symbolize_names: true)
      { success: true, data: parsed_response }
    else
      handle_failed_response(response)
    end
  end

  def handle_failed_response(response)
    Rails.logger.error(
      "FastAPI request failed: Status=#{response.status}, Body=#{response.body}"
    )
    { success: false, error: "FastAPI analysis failed: Status #{response.status}" }
  end

  def handle_faraday_error(error)
    Rails.logger.error(
      "FastAPI connection error: #{error.class.name} - #{error.message}"
    )
    { success: false, error: "FastAPI connection error: #{error.class.name}" }
  end

  def handle_json_parse_error(error)
    Rails.logger.error("FastAPI JSON parse error: #{error.message}")
    { success: false, error: 'Failed to parse FastAPI response.' }
  end

  def handle_unexpected_error(error)
    Rails.logger.error(
      "Unexpected error in FastApiAnalyzerService for VoiceConditionLog ID #{@voice_condition_log.id}: " \
      "#{error.class.name} - #{error.message}\n#{error.backtrace.join("\n")}"
    )
    { success: false, error: 'An unexpected server error occurred during analysis.' }
  end
end
