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

    if (!alreadyAnalyzed && !hasInitialError) {
      this.subscribeToChannel();
    } else {
      console.log(`Record ${this.recordIdValue}: Not subscribing via ActionCable. Initial state: Analyzed=${alreadyAnalyzed}, Error=${hasInitialError}`);
    }
  }

  subscribeToChannel() {
    if (this.subscription) { // 既に購読中なら何もしないか、一度解除して再購読
      this.subscription.unsubscribe();
    }

    console.log(`Subscribing to VoiceConditionLogAnalysisChannel for ID ${this.recordIdValue}`);
    this.subscription = consumer.subscriptions.create(
      { channel: "VoiceConditionLogAnalysisChannel", id: this.recordIdValue }, // サーバーサイドのparams[:id]に渡す
      {
        connected: () => {
          console.log(`Successfully connected to VoiceConditionLogAnalysisChannel for ID ${this.recordIdValue}`);
          // 接続成功時に、万が一のために現在の状態を一度取得するポーリングを1回だけ行うことも検討可能 (今回は省略)
        },
        disconnected: (reason) => {
          console.log(`Disconnected from VoiceConditionLogAnalysisChannel for ID ${this.recordIdValue}. Reason:`, reason);
        },
        received: (data) => {
          console.log(`Received data for record ${this.recordIdValue}:`, data);
          if (data.html_content) {
            this.resultsAreaTarget.innerHTML = data.html_content;
            console.log(`Updated resultsArea for record ${this.recordIdValue} via ActionCable.`);
            // 結果を受け取ったら購読を解除しても良い場合がある
            // this.unsubscribeFromChannel();
          } else if (data.error_message) { // ジョブがエラーメッセージをブロードキャストする場合
            this.resultsAreaTarget.innerHTML = `<div class="p-4 text-sm text-red-700 bg-red-100 rounded-lg shadow-sm" role="alert"><span class="font-medium">分析エラー：</span> ${data.error_message}</div>`;
            this.unsubscribeFromChannel();
          }
          // "分析中"でなくなったことを確認してunsubscribeするロジックをここに含めることも可能
          const analysisInProgressElement = this.resultsAreaTarget.querySelector('.text-blue-700 .font-medium');
          const analysisErrorElement = this.resultsAreaTarget.querySelector('.text-red-700 .font-medium');
          if (!analysisInProgressElement || analysisErrorElement) {
            this.unsubscribeFromChannel();
          }
        }
      }
    );
  }

  unsubscribeFromChannel() {
    if (this.subscription) {
      this.subscription.unsubscribe();
      this.subscription = null;
      console.log(`Unsubscribed from VoiceConditionLogAnalysisChannel for ID ${this.recordIdValue}`);
    }
  }

  disconnect() {
    this.unsubscribeFromChannel();
    console.log(`AnalysisUpdaterController for ID ${this.recordIdValue} disconnected.`);
  }
}