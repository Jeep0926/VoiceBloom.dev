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

  # 録音データを受け取り、PracticeAttemptLogを作成・保存するロジック
  def create
    @practice_attempt_log = build_practice_attempt_log

    if @practice_attempt_log.save!
      handle_successful_attempt_log_creation
    else
      handle_failed_attempt_log_creation
    end
  end

  private

  def set_practice_session_log
    # ネストされたURL (/practice_session_logs/:practice_session_log_id/...) からセッションIDを取得
    @practice_session_log = current_user.practice_session_logs.find(params[:practice_session_log_id])
  end

  def practice_attempt_log_params
    params.require(:practice_attempt_log).permit(:recorded_audio, :practice_exercise_id)
  end

  def build_practice_attempt_log
    @practice_session_log.practice_attempt_logs.create(
      practice_attempt_log_params.merge(
        user: @practice_session_log.user, # 整合性を保証
        attempted_at: Time.current,
        # 現在のセッションの試行回数に1を足して、今回の試行番号を設定
        attempt_number: @practice_session_log.practice_attempt_logs.count + 1
      )
    )
  end

  def handle_successful_attempt_log_creation
    # ★★★ ここでの reload は不要になります ★★★
    # なぜなら、`find_next_exercise` に最新のセッションオブジェクトを渡すからです

    # 次のお題に進むか、セッションを終了するかを判断
    next_exercise = find_next_exercise(@practice_session_log) # 引数でセッションを渡す
    if next_exercise
      # まだ次のお題がある場合、次の練習試行ページへリダイレクト
      redirect_to new_practice_session_log_practice_attempt_log_path(@practice_session_log,
                                                                     exercise_id: next_exercise.id)
    else
      # これが最後のお題だった場合、セッションを終了させ、結果ページへリダイレクト
      @practice_session_log.update(session_ended_at: Time.current)
      # TODO: 総合スコアを計算して保存するロジック
      redirect_to @practice_session_log, notice: '練習セッションが完了しました！' # rubocop:disable Rails/I18nLocaleTexts
    end
  end

  def handle_failed_attempt_log_creation
    # newアクションを再描画する場合は、@practice_exercise を再度設定する必要がある
    @practice_exercise = PracticeExercise.find(practice_attempt_log_params[:practice_exercise_id])
    flash.now[:alert] = "録音の保存に失敗しました: #{@practice_attempt_log.errors.full_messages.join(', ')}"
    render :new, status: :unprocessable_entity
  end

  # 次のお題を見つけるためのヘルパーメソッド
  def find_next_exercise(session)
    # 機能的には不要（これは、「create」メソッドの主語がアソシエーション経由のモデル「@practice_session_log.practice_attempt_logs」であるため
    # railsがよしなにDBにもメモリにも記録してくれるため）だが、人為的ミスの防止やコードの意図の明確化と将来的な堅牢性の観点から「reload」はつけておく！
    session.reload

    # 引数で渡されたセッションオブジェクトの関連レコードからIDを取得
    # これにより、@practice_session_log インスタンス変数の状態に依存しない
    attempted_exercise_ids = session.practice_attempt_logs.pluck(:practice_exercise_id).compact

    # まだ試行していない、有効なお題をランダムに1つ取得
    PracticeExercise.where(is_active: true).where.not(id: attempted_exercise_ids).order('RANDOM()').first
  end
end
