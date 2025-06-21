# frozen_string_literal: true

class LearningLogsController < ApplicationController
  before_action :authenticate_user!
  layout 'base_view' # 共通のタスク画面用レイアウトを適用

  def show
    prepare_voice_data
    prepare_practice_data
  end

  private

  def prepare_voice_data
    load_voice_condition_logs
    build_chart_data
  end

  def load_voice_condition_logs
    # 直近5件のコンディション記録を取得し、グラフ用に整形（グラフと履歴表示のために、古い順に並べ替える）
    @voice_condition_logs = current_user.voice_condition_logs.order(created_at: :desc).limit(5)
    # DBから取得した配列は不変なので、新しい変数に代入する
    @sorted_voice_condition_logs = @voice_condition_logs.reverse
  end

  def build_chart_data
    @chart_data = @voice_condition_logs.map do |log|
      {
        # l() ヘルパーで "6/19" のような形式の日付ラベルを作成
        date: l(log.created_at, format: :short_date),
        # 各分析値を格納
        pitch: log.pitch_score,
        tempo: log.tempo_score,
        volume: log.volume_score
      }
    end
  end

  # 発声練習関連のデータを準備する
  def prepare_practice_data
    all_sessions = load_all_practice_sessions
    prepare_practice_chart_data(all_sessions)
    prepare_practice_history_data(all_sessions)
  end

  # N+1問題を考慮して全ての練習セッションを読み込む
  def load_all_practice_sessions
    current_user.practice_session_logs
                .includes(practice_attempt_logs: [:practice_exercise,
                                                  { recorded_audio_attachment: :blob }])
                .order(created_at: :desc)
  end

  # 練習スコア推移グラフのデータを準備する
  def prepare_practice_chart_data(sessions)
    # 完了済みセッションの直近5件を古い順に取得
    sessions_for_chart = sessions.where.not(session_ended_at: nil).first(5).reverse
    # Chart.jsが扱いやすい形式の配列を構築する
    @practice_chart_data = sessions_for_chart.map do |session|
      {
        date: l(session.created_at, format: :short),
        score: session.total_score || 460 # ダミーのスコア
      }
    end
  end

  # 練習履歴一覧と最新の履歴詳細のデータを準備する
  def prepare_practice_history_data(sessions)
    @practice_session_logs = sessions.first(5)
    @latest_practice_session = sessions.first
  end
end
