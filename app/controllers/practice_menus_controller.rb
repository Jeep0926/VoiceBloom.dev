# frozen_string_literal: true

class PracticeMenusController < ApplicationController
  before_action :authenticate_user!
  layout 'base_view'

  def index
    # 有効なお題をカテゴリでグループ化
    # 「声キャラ」作成用の録音画面（オンボーディング）を非表示にするため
    # is_for_onboarding が false の練習問題のみを対象にする
    exercises = PracticeExercise.where(is_active: true, is_for_onboarding: false)
                                .includes(:sample_audio_attachment)

    @exercises_by_category = exercises.group_by(&:category)

    # おすすめトレーニング用に、カテゴリのリストをビューに渡す
    # 将来的に、ここでおすすめのロジックを実装できる
    @recommended_categories = @exercises_by_category.keys
  end
end
