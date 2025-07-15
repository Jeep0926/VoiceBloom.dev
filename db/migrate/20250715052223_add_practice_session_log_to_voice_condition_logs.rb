class AddPracticeSessionLogToVoiceConditionLogs < ActiveRecord::Migration[7.2]
  def change
    # NULL を許可した状態でカラムを追加する
    # 「声のコンディション確認」機能で作成される VoiceConditionLog は
    # どのセッションにも属さないため、このカラムは NULL になるため
    add_reference :voice_condition_logs, :practice_session_log, null: true, foreign_key: true
  end
end
