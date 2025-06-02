import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer" // consumer.js からインポート

export default class extends Controller {
  static targets = [ "resultsArea" ]
  static values = {
    recordId: Number, // voice_condition_log の ID
    initialAnalyzedAt: String,
    initialErrorMessage: String
  }

  subscription = null;

  connect() {
    const alreadyAnalyzed = this.initialAnalyzedAtValue === "true";
    const hasInitialError = this.initialErrorMessageValue === "true";

    if (!this.recordIdValue) {
      console.error("AnalysisUpdaterController: recordIdValue is missing.");
      return;
    }

    // 初回表示時に分析済みでもエラーでもない場合のみ購読
    if (!alreadyAnalyzed && !hasInitialError) {
      this.subscribeToChannel();
    } else {
      console.log(`Record ${this.recordIdValue}: Not subscribing via ActionCable. Initial state: Analyzed=${alreadyAnalyzed}, Error=${hasInitialError}`);
    }
  }

  subscribeToChannel() {
    // 既に何らかの理由で購読中の場合、念のため古い購読を解除
    if (this.subscription) {
      console.log(`Unsubscribing previous subscription before creating a new one for ID ${this.recordIdValue}.`);
      this.subscription.unsubscribe();
      this.subscription = null; // 明示的にnullに戻す
    }

    console.log(`Subscribing to VoiceConditionLogAnalysisChannel for ID ${this.recordIdValue}`);
    this.subscription = consumer.subscriptions.create(
      { channel: "VoiceConditionLogAnalysisChannel", id: this.recordIdValue },
      {
        connected: () => {
          console.log(`Successfully connected to VoiceConditionLogAnalysisChannel for ID ${this.recordIdValue}`);
          // 接続成功時に現在の状態を一度だけ取得する
          this.requestCurrentAnalysisResult();
        },
        disconnected: (reason) => {
          console.log(`Disconnected from VoiceConditionLogAnalysisChannel for ID ${this.recordIdValue}. Reason:`, reason);
          // 予期せぬ切断の場合、再接続ロジックをここに入れることも検討可能 (今回は省略)
        },
        received: (data) => {
          console.log(`!!!! AnalysisUpdaterController: RECEIVED METHOD CALLED for record ${this.recordIdValue} !!!!`);
          console.log(`Received data for record ${this.recordIdValue}:`, data);

          if (data.html_content) {
            this.resultsAreaTarget.innerHTML = data.html_content;
            console.log(`Updated resultsArea for record ${this.recordIdValue} with received html_content.`);

            // 分析結果 (成功またはエラーメッセージを含むHTML) を受信し表示が完了したので、
            // この特定の voice_condition_log に対する購読は解除する。
            // これにより、同じページに留まり続けた場合に不要な購読が残るのを防ぐ。
            // 次の録音・分析では新しいページに遷移し、新しいコントローラーインスタンスが新しい購読を行う想定。
            this.unsubscribeFromChannel();

          } else {
            // data.html_content がない場合は、予期せぬデータ形式の可能性がある
            console.warn(`Received data for record ${this.recordIdValue} without html_content:`, data);
            // この場合も、何らかの終端状態とみなし、購読を解除するかどうか検討
            // this.unsubscribeFromChannel();
          }
        }
      }
    );
  }

  requestCurrentAnalysisResult() {
    // 購読が確立されていることを確認してから perform を呼び出す
    if (this.subscription && this.subscription.consumer.connection.isOpen()) {
      console.log(`Requesting current analysis state for ID ${this.recordIdValue} via ActionCable perform`);
      this.subscription.perform('request_current_state');
    } else {
      console.warn(`Cannot request current analysis state for ID ${this.recordIdValue}: Subscription not active or connection closed.`);
      // 購読がまだ確立されていないか、既に閉じている場合は、少し待ってから再試行するロジックを検討することも可能 (今回は省略)
    }
  }

  unsubscribeFromChannel() {
    if (this.subscription) {
      this.subscription.unsubscribe();
      this.subscription = null; // 購読解除後は subscription オブジェクトをクリア
      console.log(`Unsubscribed from VoiceConditionLogAnalysisChannel for ID ${this.recordIdValue}`);
    }
  }

  disconnect() {
    // StimulusコントローラーがDOMからデタッチされるときに呼ばれる
    // 確実に購読を解除する
    console.log(`AnalysisUpdaterController for ID ${this.recordIdValue} disconnecting...`);
    this.unsubscribeFromChannel();
  }
}