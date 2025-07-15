# frozen_string_literal: true

class VoiceConditionLog < ApplicationRecord
  belongs_to :user
  # practice_session_log との関連付けを追加。この関連は必須ではないため optional: true
  # practice_session_log_id が nil であってもバリデーションエラーにならないようにするため
  belongs_to :practice_session_log, optional: true

  has_one_attached :recorded_audio # 録音された音声ファイルをアタッチする

  # 声のコンディションを記録する際、どのフレーズに対して録音・分析したのかという情報は
  # 後から記録を見返す上でとっても重要!
  # この情報がないと、分析結果の数値（高さ、速さ、音量）が何に対するものなのか分からなくなる。
  validates :phrase_text_snapshot, presence: true, length: { maximum: 255 }

  # 音声分析の各パラメータの取る数値がバラバラなため正規化してグラフで表示した時、ユーザーにわかりやすく伝えるため正規化する
  # 声の高さ (ピッチ) をスコア化 (0-100点)
  def pitch_score
    return nil if pitch_value.blank?

    ideal_pitch, range = ideal_pitch_range
    distance = (pitch_value - ideal_pitch).abs
    score = 100 - (distance / range * 50)
    [0, score.round].max
  end

  # 話す速さ (テンポ) をスコア化 (0-100点)
  def tempo_score
    return nil if tempo_value.blank?

    ideal_tempo = 330.0 # 音節/分
    range = 30.0 # 許容範囲の半径
    distance = (tempo_value - ideal_tempo).abs
    score = 100 - (distance / range * 50)
    [0, score.round].max
  end

  # 声の音量 (ボリューム) をスコア化 (0-100点)
  def volume_score
    return nil if volume_value.blank?

    ideal_volume = -20.0 # dBFS
    range = 5.0          # 許容範囲の半径
    distance = (volume_value - ideal_volume).abs
    score = 100 - (distance / range * 50)
    [0, score.round].max
  end

  private

  # 性別に応じた理想ピッチと許容範囲を返す
  def ideal_pitch_range
    if user.male?
      [110.0, 25.0] # 中心: 110Hz, 許容範囲の半径: 25Hz
    elsif user.female?
      [220.0, 35.0] # 中心: 220Hz, 許容範囲の半径: 35Hz
    else
      [165.0, 30.0] # デフォルト（その他）: 中心165Hz, 許容範囲30Hz
    end
  end
end
