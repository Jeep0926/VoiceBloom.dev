# frozen_string_literal: true

class BaselineCalculatorService
  def initialize(user)
    @user = user
  end

  def call
    recent_logs = fetch_recent_logs
    # 計算対象のログがなければ何もしない
    return false if recent_logs.empty?

    baselines = calculate_baselines(recent_logs)
    update_user_baseline(baselines)

    true # 成功したことを示す
  end

  private

  # ユーザーに紐づく、分析済みのコンディション記録を直近30件取得
  # オンボーディングで作成されたログも、通常のログも全て対象
  def fetch_recent_logs
    @user.voice_condition_logs
         .where.not(analyzed_at: nil) # 分析が完了しているもののみ
         .order(created_at: :desc)
         .limit(30)
  end

  # 各指標の平均値を計算
  def calculate_baselines(logs)
    {
      pitch: calculate_average(logs.pluck(:pitch_value)),
      tempo: calculate_average(logs.pluck(:tempo_value)),
      volume: calculate_average(logs.pluck(:volume_value))
    }
  end

  # ユーザーモデルに基準値を保存
  def update_user_baseline(baselines)
    @user.update!(
      baseline_pitch: baselines[:pitch],
      baseline_tempo: baselines[:tempo],
      baseline_volume: baselines[:volume]
    )
  end

  # nilを除外して配列の平均値を計算するヘルパーメソッド
  def calculate_average(values)
    valid_values = values.compact
    return nil if valid_values.empty?

    # .to_f を追加し、整数同士の割り算で結果が丸められてしまうのを防ぐ
    (valid_values.sum.to_f / valid_values.size).round(2)
  end
end
