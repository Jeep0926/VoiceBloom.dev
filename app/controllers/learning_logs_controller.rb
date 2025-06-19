# frozen_string_literal: true

class LearningLogsController < ApplicationController
  before_action :authenticate_user!
  layout 'base_view' # 共通のタスク画面用レイアウトを適用

  def show
    prepare_voice_data
    prepare_practice_session_logs
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

  # 発声練習セッション履歴を取得
  def prepare_practice_session_logs
    @practice_session_logs = current_user.practice_session_logs
                                         .includes(practice_attempt_logs: :practice_exercise)
                                         .order(created_at: :desc) # こちらは新しい順のままでOK！
                                         .limit(5)
  end
end
