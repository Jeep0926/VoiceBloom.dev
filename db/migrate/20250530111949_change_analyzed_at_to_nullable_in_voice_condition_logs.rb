class ChangeAnalyzedAtToNullableInVoiceConditionLogs < ActiveRecord::Migration[7.2]
  def change
    change_column_null :voice_condition_logs, :analyzed_at, true
  end
end
