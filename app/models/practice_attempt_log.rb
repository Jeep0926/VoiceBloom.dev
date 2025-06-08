# frozen_string_literal: true

class PracticeAttemptLog < ApplicationRecord
  belongs_to :user
  belongs_to :practice_exercise
  belongs_to :practice_session_log

  has_one_attached :recorded_audio

  # --- recorded_audio のバリデーション ---
  validates :recorded_audio, presence: true # 録音音声は必須
  validates :recorded_audio, content_type: {
    in: ['audio/x-wav', 'audio/mpeg'],
    message: 'はWAVまたはMP3形式のファイルをアップロードしてください。' # rubocop:disable Rails/I18nLocaleTexts
  }
  validates :recorded_audio, size: {
    less_than: 20.megabytes, # ネットで調べたところ、10秒の音声データの場合、最大容量は10MB強となることが分かった。👉余裕を持たせて20MBに設定。
    message: 'のファイルサイズは20MBを超えることはできません。' # rubocop:disable Rails/I18nLocaleTexts
  }

  # --- attempted_at のバリデーション ---
  # DBで NOT NULL 制約をかけたので、モデルでも presence を検証
  validates :attempted_at, presence: true

  # score： 値があるなら0-100の整数
  validates :score, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100,
    allow_nil: true
  }

  # attempt_number（練習問題の表示数とその順番を管理）： 値があるなら1-5の整数
  # 「そのセッション（発声練習）における何番目のお題か」を必ず示すようにしたい
  # このため、nil を許容せず、常に1以上の値を持つように設定した
  validates :attempt_number, presence: true, numericality: {
    only_integer: true, greater_than_or_equal_to: 1,
    less_than_or_equal_to: 5
  }

  # feedback_text： 文字数制限。適宜調整する。（フィードバックなので少し長めに設定しておく）
  validates :feedback_text, length: { maximum: 255, allow_nil: true } # 例: 1000文字に緩和
end
