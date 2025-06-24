class AddDurationMinutesToPracticeExercises < ActiveRecord::Migration[7.2]
  def change
    # 整数型で分単位の所要時間を保存。デフォルトは1分とする。
    add_column :practice_exercises, :duration_minutes, :integer, default: 1, null: false
  end
end
