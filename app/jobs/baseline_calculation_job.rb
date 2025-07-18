# frozen_string_literal: true

class BaselineCalculationJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user # ユーザーが存在しない場合は何もしない

    # ベースライン計算サービスを呼び出す
    success = BaselineCalculatorService.new(user).call

    return unless success

    # 基準値の計算が成功したら、次にキャラクター生成ジョブを実行する
    CharacterGenerationJob.perform_later(user.id)
  end
end
