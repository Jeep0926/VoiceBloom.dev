# frozen_string_literal: true

class PracticeExercise < ApplicationRecord
  # Active Storageを使用して sample_audio という名前でファイルをアタッチ
  has_one_attached :sample_audio

  has_many :practice_attempt_logs, dependent: :destroy # エクササイズ削除時に試行ログも削除

  validates :title, presence: true, length: { maximum: 30 }
  validates :text_content, presence: true

  # 入力される場合は必ず意味のある文字列であってほしいが、未入力（NULL）は許可したいため
  validates :category, length: { maximum: 10, allow_nil: true }
  # 将来的に下記を検討する
  # validates :category, presence: true, inclusion: { in: %w(滑舌 音程 長文 その他) }

  # difficulty_level はNULLを許可。もし1-5のような範囲にする場合を想定
  validates :difficulty_level, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 5,
    allow_nil: true
  }

  # true または false のどちらか
  validates :is_active, inclusion: { in: [true, false] }
end
