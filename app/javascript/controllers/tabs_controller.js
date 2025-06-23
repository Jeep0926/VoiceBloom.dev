import { Controller } from "@hotwired/stimulus"

// タブ切り替えを管理するコントローラー
export default class extends Controller {
  static targets = [ "tab", "panel" ]
  static classes = [ "activeTab", "inactiveTab" ]

  connect() {
    // URLから 'tab' パラメータを取得
    const params = new URLSearchParams(window.location.search);
    const tabNameToOpen = params.get('tab');

    let initialIndex = 0; // デフォルトは最初のタブ (0番目)

    // 'tab' パラメータに応じて初期表示するタブのインデックスを決定
    if (tabNameToOpen === 'practice') {
      initialIndex = 1; // 2番目のタブ (発声練習)
    }

    // 決定したインデックスのタブを表示
    this.showTab(initialIndex);
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