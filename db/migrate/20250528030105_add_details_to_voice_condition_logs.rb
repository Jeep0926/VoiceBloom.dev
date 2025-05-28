class AddDetailsToVoiceConditionLogs < ActiveRecord::Migration[7.2]
  def change
    add_column :voice_condition_logs, :duration_seconds, :float
    add_column :voice_condition_logs, :analysis_error_message, :text, null: true
  end
end
