# frozen_string_literal: true

module ApplicationHelper
  def bottom_nav_class(path)
    if current_page?(path)
      'text-purple-600 font-bold' # アクティブ時のCSSクラス
    else
      'text-gray-500 hover:text-purple-600' # 非アクティブ時のCSSクラス
    end
  end

  # ヘッダー用の「ホームへ戻る」リンクを生成するヘルパー
  def home_back_link
    # link_to ヘルパーを使って、ログイン後のルートパスへのリンクを作成
    link_to authenticated_root_path, class: 'text-gray-600 p-2 flex items-center' do
      # 戻るアイコンのSVG
      svg_icon = content_tag(:svg, class: 'h-6 w-6', xmlns: 'http://www.w3.org/2000/svg', fill: 'none',
                                   viewBox: '0 0 24 24', 'stroke-width': '2.5', stroke: 'currentColor') do
        content_tag(:path, nil, 'stroke-linecap': 'round', 'stroke-linejoin': 'round', d: 'M15.75 19.5L8.25 12l7.5-7.5')
      end

      # アイコンとテキストを結合して返す
      svg_icon + content_tag(:span, 'ホームへ', class: 'text-sm font-medium ml-1')
    end
  end
end
