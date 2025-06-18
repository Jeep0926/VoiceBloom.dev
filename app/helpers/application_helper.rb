# frozen_string_literal: true

module ApplicationHelper
  def bottom_nav_class(path)
    if current_page?(path)
      'text-purple-600 font-bold' # アクティブ時のCSSクラス
    else
      'text-gray-500 hover:text-purple-600' # 非アクティブ時のCSSクラス
    end
  end
end
