# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :set_show_bottom_nav

  private

  # デフォルトで下部ナビゲーションを表示する設定
  def set_show_bottom_nav
    @show_bottom_nav = true
  end
end
