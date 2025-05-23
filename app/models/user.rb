# frozen_string_literal: true

class User < ApplicationRecord
  include Discard::Model
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, presence: true, length: { maximum: 30 }

  has_one_attached :profile_image

  # 論理削除したユーザーを検索対象に含めないため
  default_scope { kept }
end
