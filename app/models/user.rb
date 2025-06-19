# frozen_string_literal: true

class User < ApplicationRecord
  include Discard::Model
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, presence: true, length: { maximum: 30 }

  has_one_attached :profile_image
  has_many :voice_condition_logs, dependent: :destroy
  has_many :practice_session_logs, dependent: :destroy
  has_many :practice_attempt_logs, dependent: :destroy # 直接持つ場合、またはセッション経由で持つ場合は不要

  # 論理削除したユーザーを検索対象に含めないため
  default_scope { kept }

  # enum を使って gender の値をシンボルで扱えるようにする
  enum gender: { unset: 0, male: 1, female: 2 }
end
