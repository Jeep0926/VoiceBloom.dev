# frozen_string_literal: true

class PracticeSessionLogsController < ApplicationController
  before_action :authenticate_user! # 全てのアクションでログインを必須にする
  layout 'task_view', only: [:show]

  def show
    # このセッションの結果をまとめて表示するページ (後のタスクでビューを実装)
    @practice_session_log = current_user.practice_session_logs.find(params[:id])
  end

  def create
    # パラメータからカテゴリを受け取る
    category = params[:category]
    @practice_session_log = create_practice_session_log

    # カテゴリに基づいて最初のお題を見つける
    first_exercise = find_first_exercise(category)

    redirect_to_first_attempt_or_root(first_exercise)
  rescue ActiveRecord::RecordInvalid => e
    handle_create_error(e)
  end

  private

  def create_practice_session_log
    current_user.practice_session_logs.create!(
      session_started_at: Time.current,
      # 「app/models/practice_session_log.rb」で、「session_type」属性に enum で定義
      # normal_practice（通常の練習）か onboarding のどちらかの値を持つことがバリデーションで必須としているため
      session_type: 'normal_practice' # "通常の練習"セッションであることを明記
    )
  end

  def find_first_exercise(category)
    # scope を is_active: true, is_for_onboarding: false に限定
    base_scope = PracticeExercise.where(is_active: true, is_for_onboarding: false)

    # もしカテゴリが指定されていれば、そのカテゴリのお題を全て取得
    if category.present?
      exercises_in_category = base_scope.where(category: category)
      # そのカテゴリにお題が存在すれば、その中からランダムに1つ返す
      return exercises_in_category.order('RANDOM()').first if exercises_in_category.exists?
    end

    # カテゴリが指定されていない、または指定されたカテゴリにお題がなかった場合、
    # 全ての通常練習用のお題からランダムに1つ返す
    base_scope.order('RANDOM()').first
  end

  def redirect_to_first_attempt_or_root(first_exercise)
    if first_exercise
      redirect_to_first_attempt(first_exercise)
    else
      redirect_to_no_exercises_available
    end
  end

  def redirect_to_first_attempt(exercise)
    redirect_to(
      new_practice_session_log_practice_attempt_log_path(
        @practice_session_log,
        exercise_id: exercise.id
      )
      # notice: '練習セッションを開始します！'
    )
  end

  def redirect_to_no_exercises_available
    # 遷移元がメニュー一覧画面の場合、そこに戻すのが親切
    redirect_back fallback_location: root_path, alert: '現在、練習できるお題がありません。' # rubocop:disable Rails/I18nLocaleTexts
  end

  def handle_create_error(exception)
    redirect_back fallback_location: root_path, alert: "セッションの開始に失敗しました: #{exception.message}"
  end
end
