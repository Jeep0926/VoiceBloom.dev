require 'faraday'
require 'faraday/multipart'

class FastApiAnalyzerService
  FASTAPI_URL = ENV.fetch('FASTAPI_URL', 'http://api:8000') # Docker Compose内のFastAPIサービス名
  ANALYZE_PATH = '/analyze/voice_condition'.freeze

  def initialize(voice_condition_log)
    @voice_condition_log = voice_condition_log
    @audio_blob = @voice_condition_log.recorded_audio.blob
  end

  def call
    return { success: false, error: 'Audio file not attached or found.' } unless @audio_blob

    connection = Faraday.new(url: FASTAPI_URL) do |faraday|
      faraday.request :multipart
      faraday.request :url_encoded
      faraday.adapter Faraday.default_adapter
      faraday.options.timeout = 20 # 分析に時間がかかる可能性を考慮し少し長めに
      faraday.options.open_timeout = 5
    end

    begin
      @audio_blob.open do |tempfile| # Active Storageからファイルを一時的に開く
        payload = {
          file: Faraday::Multipart::FilePart.new(
            tempfile.path,
            @audio_blob.content_type,
            @audio_blob.filename.to_s
          )
        }
        response = connection.post(ANALYZE_PATH, payload)

        if response.success?
          parsed_response = JSON.parse(response.body, symbolize_names: true)
          { success: true, data: parsed_response }
        else
          Rails.logger.error "FastAPI request failed: Status=#{response.status}, Body=#{response.body}"
          { success: false, error: "FastAPI analysis failed: Status #{response.status}" }
        end
      end
    rescue Faraday::Error => e
      Rails.logger.error "FastAPI connection error: #{e.class.name} - #{e.message}"
      { success: false, error: "FastAPI connection error: #{e.class.name}" }
    rescue JSON::ParserError => e
      Rails.logger.error "FastAPI JSON parse error: #{e.message}"
      { success: false, error: 'Failed to parse FastAPI response.' }
    rescue StandardError => e
      Rails.logger.error "Unexpected error in FastApiAnalyzerService for VoiceConditionLog ID #{@voice_condition_log.id}: #{e.class.name} - #{e.message}\n#{e.backtrace.join("\n")}"
      { success: false, error: "An unexpected server error occurred during analysis." }
    end
  end
end