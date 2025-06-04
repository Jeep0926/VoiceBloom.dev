class UpdateNullConstraintsForLogTimestamps < ActiveRecord::Migration[7.2]
  def change
    change_column_null :practice_session_logs, :session_started_at, false

    change_column_null :practice_attempt_logs, :attempted_at, false

    change_column_null :voice_condition_logs, :phrase_text_snapshot, false
  end
end
