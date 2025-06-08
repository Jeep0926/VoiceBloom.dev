# frozen_string_literal: true

class PracticeAttemptLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_practice_session_log, only: %i[new create]
  layout 'base_view', only: %i[new show]

  def show
    # 個別の試行結果を表示するページ (後のタスクで実装)
    @practice_attempt_log = current_user.practice_attempt_logs.find(params[:id])
  end

  def new
    # 1. 表示するお題(エクササイズ)を取得
    #    リダイレクト元の PracticeSessionsController#create から渡された exercise_id パラメータを使用
    @practice_exercise = PracticeExercise.find(params[:exercise_id])

    # 2. 新しい試行ログオブジェクトをメモリ上に作成 (まだ保存はしない)
    #    フォームの送信先URLなどを生成するために使う
    @practice_attempt_log = @practice_session_log.practice_attempt_logs.build(
      practice_exercise: @practice_exercise,
      # attempt_number は、このセッションの既存の試行回数+1で設定
      attempt_number: @practice_session_log.practice_attempt_logs.count + 1
    )
  end

  def create
    # 録音データを受け取り、PracticeAttemptLogを作成・保存するロジック
    # (これは、この後のタスクで実装します)
    # ここでは仮にプレースホルダとしておきます
    render plain: 'Create action will be implemented later.'
  end

  private

  def set_practice_session_log
    # ネストされたURL (/practice_session_logs/:practice_session_log_id/...) からセッションIDを取得
    @practice_session_log = current_user.practice_session_logs.find(params[:practice_session_log_id])
  end
end
