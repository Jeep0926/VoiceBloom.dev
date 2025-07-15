# frozen_string_literal: true

class BaselineCalculationJob < ApplicationJob
  queue_as :default

  def perform(user_id, session_id)
    user = User.find(user_id)
    onboarding_session = PracticeSessionLog.find(session_id)

    # ベースライン計算サービスを呼び出す
    success = BaselineCalculatorService.new(user, onboarding_session).call

    # サービスが失敗した場合はここで処理を終了する（ガード節）
    # TODO: エラーハンドリング (例: ユーザーに通知を送るなど)
    return unless success

    # 基準値の計算が成功したら、次にキャラクター生成ジョブを実行する
    CharacterGenerationJob.perform_later(user.id)
  end
end
