class AddOnboardingFieldsToUsersAndExercises < ActiveRecord::Migration[7.2]
  def change
    # practice_exercises テーブルへの追加
    add_column :practice_exercises, :is_for_onboarding, :boolean, default: false, null: false

    # users テーブルへの追加
    add_column :users, :onboarding_status, :integer, default: 0, null: false
    add_column :users, :baseline_pitch, :float
    add_column :users, :baseline_tempo, :float
    add_column :users, :baseline_volume, :float
  end
end
