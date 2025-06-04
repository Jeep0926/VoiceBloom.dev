class CreatePracticeSessionLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :practice_session_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :total_score
      t.datetime :session_started_at
      t.datetime :session_ended_at
      t.boolean :is_shared_on_sns, default: false, null: false

      t.timestamps
    end
  end
end
