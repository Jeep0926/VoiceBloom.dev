# frozen_string_literal: true

class BaselineCalculatorService
  def initialize(user, onboarding_session)
    @user = user
    @onboarding_session = onboarding_session
  end

  def call
    # TODO: 3つの録音ログから平均値を計算し、ユーザーの基準値を更新するロジックをここに実装
    Rails.logger.info "Calculating baseline for User ID: #{@user.id}..."
    # MVPでは、仮に固定値を保存してみる
    @user.update!(
      baseline_pitch: 150.0,
      baseline_tempo: 300.0,
      baseline_volume: -20.0
    )
    Rails.logger.info "Baseline updated for User ID: #{@user.id}."
    true # 成功した場合はtrueを返す
  end
end
