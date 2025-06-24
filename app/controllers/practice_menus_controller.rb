# frozen_string_literal: true

class PracticeMenusController < ApplicationController
  before_action :authenticate_user!
  layout 'base_view'

  def index
    # 有効なお題をカテゴリでグループ化
    # .includes(:sample_audio_attachment) でN+1問題を予防
    exercises = PracticeExercise.where(is_active: true).includes(:sample_audio_attachment)
    @exercises_by_category = exercises.group_by(&:category)

    # おすすめトレーニング用に、カテゴリのリストをビューに渡す
    # 将来的に、ここでおすすめのロジックを実装できる
    @recommended_categories = @exercises_by_category.keys
  end
end
