# frozen_string_literal: true

class PracticeSessionLog < ApplicationRecord
  belongs_to :user
  has_many :practice_attempt_logs, dependent: :destroy # 1つのセッションは多数の試行ログを持つ

  # session_type カラムを enum として定義
  enum :session_type, {
    normal_practice: 'normal_practice', # 通常の練習
    onboarding: 'onboarding'            # オンボーディング
  }

  validates :session_type, inclusion: { in: session_types.keys }

  # --- session_started_at のバリデーション ---
  # DBで NOT NULL 制約をかけたので、モデルでも presence を検証
  validates :session_started_at, presence: true

  # --- session_ended_at のバリデーション ---
  # session_ended_at は session_started_at より後であるべき (両方存在する場合)
  validate :session_ended_at_after_session_started_at, if: lambda {
    session_started_at.present? && session_ended_at.present?
  }

  # total_score： 値があるなら0以上の整数 (上限は要件次第)
  validates :total_score, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 500, # 5問 x 100点満点のため
    allow_nil: true
  }

  validates :is_shared_on_sns, inclusion: { in: [true, false] }

  # このセッションの代表タイトルを返すメソッド
  # 最初の試行ログに紐づくエクササイズのタイトルを返す
  def representative_title
    # practice_attempt_logs.first は created_at の昇順で最初のものを取るため、
    # order を指定して常に一貫した結果を返すようにする
    first_attempt = practice_attempt_logs.order(:created_at).first
    first_attempt&.practice_exercise&.title || '発声練習' # もし見つからなければデフォルト値を返す
  end

  private

  def session_ended_at_after_session_started_at
    return unless session_ended_at < session_started_at

    errors.add(:session_ended_at, 'はセッション開始日時より後である必要があります。')
  end
end
