# frozen_string_literal: true

class CharacterImage < ApplicationRecord
  belongs_to :user
  has_one_attached :image # 画像ファイルは 'image' という名前で紐付ける
end
