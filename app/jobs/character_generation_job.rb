# frozen_string_literal: true

class CharacterGenerationJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)

    # キャラクター生成サービスを呼び出す
    success = CharacterGeneratorService.new(user).call

    # サービスが失敗した場合はここで処理を終了する（ガード節）
    # TODO: エラーハンドリング
    return unless success

    # TODO: 成功したことをAction Cableでブラウザに通知する
  end
end
