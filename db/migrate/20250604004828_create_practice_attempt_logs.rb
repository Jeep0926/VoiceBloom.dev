class CreatePracticeAttemptLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :practice_attempt_logs do |t|
      t.references :practice_session_log, null: false, foreign_key: true
      t.references :practice_exercise, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :score
      t.text :feedback_text
      t.integer :attempt_number
      t.datetime :attempted_at

      t.timestamps
    end
  end
end
