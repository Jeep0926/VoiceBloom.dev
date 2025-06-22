# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :set_show_bottom_nav

  private

  # デフォルトで下部ナビゲーションを表示するかどうかを決定する
  def set_show_bottom_nav
    # devise_controller? はDeviseが提供するヘルパーで、
    # 現在のコントローラーがDevise関連（ログイン、新規登録など）の場合に true を返す。
    # @show_bottom_nav には、devise_controller? が「偽 (false)」のとき true が入る。
    # つまり、「Deviseの画面じゃなければ、ナビゲーションを表示する」というルールになる。
    @show_bottom_nav = !devise_controller?
  end
end
