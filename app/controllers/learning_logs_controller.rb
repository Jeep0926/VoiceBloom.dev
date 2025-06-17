# frozen_string_literal: true

class LearningLogsController < ApplicationController
  before_action :authenticate_user!
  layout 'base_view' # 共通のタスク画面用レイアウトを適用

  def show
    # 声のコンディション履歴を新しい順で取得
    @voice_condition_logs = current_user.voice_condition_logs.order(created_at: :desc)

    # 発声練習セッション履歴を新しい順で取得
    # N+1問題を避けるため、関連する試行ログとエクササイズも事前に読み込む
    @practice_session_logs = current_user.practice_session_logs
                                         .includes(practice_attempt_logs: :practice_exercise)
                                         .order(created_at: :desc)
  end
end
