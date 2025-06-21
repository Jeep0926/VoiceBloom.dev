class AddTotalPracticeSessionsCountToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :total_practice_sessions_count, :integer, default: 0, null: false
  end
end
