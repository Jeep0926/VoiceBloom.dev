class CreateVoiceConditionLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :voice_condition_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.text :phrase_text_snapshot
      t.datetime :analyzed_at, null: false
      t.float :pitch_value
      t.float :tempo_value
      t.float :volume_value

      t.timestamps
    end
  end
end
