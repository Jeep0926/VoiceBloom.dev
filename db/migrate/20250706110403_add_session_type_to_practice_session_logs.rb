class AddSessionTypeToPracticeSessionLogs < ActiveRecord::Migration[7.2]
  def change
    add_column :practice_session_logs, :session_type, :string
  end
end
