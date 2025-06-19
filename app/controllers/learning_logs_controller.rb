# frozen_string_literal: true

class LearningLogsController < ApplicationController
  before_action :authenticate_user!
  layout 'base_view' # 共通のタスク画面用レイアウトを適用

  def show
    # 5日前の0時0分0秒の日時を取得
    start_date = 5.days.ago.beginning_of_day

    # 声のコンディション履歴を、5日前から現在までの期間で絞り込み、新しい順で取得
    @voice_condition_logs = current_user.voice_condition_logs
                                         .where(created_at: start_date..Time.current)
                                         .order(created_at: :asc) # 注意：グラフのX軸（日付）を左から右へ時系列で正しく並べるために古い順で取得する

    # 発声練習セッション履歴も同様に期間で絞り込む
    @practice_session_logs = current_user.practice_session_logs
                                         .includes(practice_attempt_logs: :practice_exercise)
                                         .where(created_at: start_date..Time.current)
                                         .order(created_at: :desc) # こちらは新しい順のままでOK！

    # グラフ描画用にデータを整形する
    @chart_data = @voice_condition_logs.map do |log|
      {
        # l() ヘルパーで "6/19" のような形式の日付ラベルを作成
        date: l(log.created_at, format: :short_date),
        # 各分析値を格納
        pitch: log.pitch_value,
        tempo: log.tempo_value,
        volume: log.volume_value
      }
    end
  end
end
