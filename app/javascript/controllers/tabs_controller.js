import { Controller } from "@hotwired/stimulus"

// タブ切り替えを管理するコントローラー
export default class extends Controller {
  static targets = [ "tab", "panel" ]
  static classes = [ "activeTab", "inactiveTab" ]

  connect() {
    // 初期状態で最初のタブを表示するだけで良くなる
    this.showTab(0);
  }

  // タブがクリックされたときに呼ばれるアクション
  change(event) {
    event.preventDefault(); // デフォルトのリンク遷移を防ぐ
    const index = this.tabTargets.indexOf(event.currentTarget);
    this.showTab(index);
  }

  // 指定された番号のタブとパネルを表示する
  showTab(index) {
    this.tabTargets.forEach((tab, i) => {
      // this.activeTabClass と this.inactiveTabClass は
      // HTMLのdata-属性から自動的に取得される
      const isActive = i === index;
      if (isActive) {
        tab.className = `${this.baseTabClasses} ${this.activeTabClass}`;
      } else {
        tab.className = `${this.baseTabClasses} ${this.inactiveTabClass}`;
      }
    });

    this.panelTargets.forEach((panel, i) => {
      panel.classList.toggle("hidden", i !== index);
    });
  }

  // 全てのタブに共通する基本クラス
  get baseTabClasses() {
    return "whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm";
  }
}