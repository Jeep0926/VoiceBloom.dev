# frozen_string_literal: true

class PracticeAttemptLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_practice_session_log, only: %i[new create]
  before_action :hide_bottom_nav, only: %i[new show] # ナビゲーション
  layout 'base_view', only: %i[new show]

  def show
    # 個別の試行結果を表示するページ
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

  # 録音データを受け取り、PracticeAttemptLogを作成・保存するロジック
  def create
    @practice_attempt_log = build_attempt_log

    if @practice_attempt_log.save
      # 保存が成功した場合
      # TODO: ここで採点用の非同期ジョブを呼び出す

      render_success_response
    else
      # 保存失敗時もJSONでエラーを返す
      render_error_response
    end
  end

  private

  # ナビゲーション非表示
  def hide_bottom_nav
    @show_bottom_nav = false
  end

  def set_practice_session_log
    # ネストされたURL (/practice_session_logs/:practice_session_log_id/...) からセッションIDを取得
    @practice_session_log = current_user.practice_session_logs.find(params[:practice_session_log_id])
  end

  def practice_attempt_log_params
    params.require(:practice_attempt_log).permit(:recorded_audio, :practice_exercise_id)
  end

  # build_attempt_log: PracticeAttemptLog を一貫して構築
  def build_attempt_log
    @practice_session_log.practice_attempt_logs.build(
      practice_attempt_log_params.merge(
        user: @practice_session_log.user,
        attempted_at: Time.current,
        attempt_number: @practice_session_log.practice_attempt_logs.count + 1
      )
    )
  end

  # 成功時の JSON レスポンスをレンダリング
  def render_success_response
    render json: {
      status: 'success',
      # 評価結果を表示するためのHTMLパーシャルをレンダリングして文字列として渡す
      result_html: render_to_string(
        partial: 'practice_attempt_logs/result_display',
        formats: [:html],
        locals: { attempt_log: @practice_attempt_log },
        layout: false
      ),
      # 次のアクションを決定
      next_action: determine_next_action(@practice_session_log)
    }
  end

  # エラー時の JSON レスポンスをレンダリング
  def render_error_response
    render json: {
      status: 'error',
      errors: @practice_attempt_log.errors.full_messages
    }, status: :unprocessable_entity
  end

  # 次のアクションを決定する
  def determine_next_action(session)
    session.reload # DBの最新の状態を反映

    if last_attempt?(session)
      finish_action(session)
    else
      next_or_finish_action(session)
    end
  end

  # セッションの試行が制限数に達しているか
  def last_attempt?(session)
    session.practice_attempt_logs.count >= session_limit
  end

  # 制限回数（1セッションあたりの問題数）
  def session_limit
    5
  end

  # セッションを終了し、終了後のハッシュを返す
  def finish_action(session)
    session.update(session_ended_at: Time.current)
    # TODO: 総合スコアを計算して保存するロジック
    { button_type: 'finish', url: practice_session_log_path(session) }
  end

  # 次の問題があれば次の画面へ、なければ終了
  def next_or_finish_action(session)
    if (next_exercise = fetch_next_exercise(session))
      { button_type: 'next',
        url: new_practice_session_log_practice_attempt_log_path(session, exercise_id: next_exercise.id) }
    else
      finish_action(session)
    end
  end

  # 次に挑戦するエクササイズを取得
  def fetch_next_exercise(session)
    attempted_ids = session.practice_attempt_logs.pluck(:practice_exercise_id).compact
    PracticeExercise.where(is_active: true)
                    .where.not(id: attempted_ids)
                    .order('RANDOM()')
                    .first
  end
end
