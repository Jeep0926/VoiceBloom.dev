# frozen_string_literal: true

class PracticeSessionLog < ApplicationRecord
  belongs_to :user
  has_many :practice_attempt_logs, dependent: :destroy # 1つのセッションは多数の試行ログを持つ

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

  private

  def session_ended_at_after_session_started_at
    return unless session_ended_at < session_started_at

    errors.add(:session_ended_at, 'はセッション開始日時より後である必要があります。')
  end
end
