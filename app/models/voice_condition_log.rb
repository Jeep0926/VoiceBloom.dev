# frozen_string_literal: true

class VoiceConditionLog < ApplicationRecord
  belongs_to :user
  has_one_attached :recorded_audio # 録音された音声ファイルをアタッチする

  # validates :analyzed_at, presence: true

  # 声のコンディションを記録する際、どのフレーズに対して録音・分析したのかという情報は
  # 後から記録を見返す上でとっても重要!
  # この情報がないと、分析結果の数値（高さ、速さ、音量）が何に対するものなのか分からなくなる。
  validates :phrase_text_snapshot, presence: true, length: { maximum: 255 }
end
