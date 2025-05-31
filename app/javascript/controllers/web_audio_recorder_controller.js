import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "startButton", "stopButton", "status", "playbackArea" ]
  // static values = { workletUrl: String } // public配下なのでValueは不要

  connect() {
    console.log("WebAudioRecorderController (AudioWorklet) connected!");
    this.isRecording = false;
    this.audioContext = null;
    this.mediaStreamSource = null;
    this.audioWorkletNode = null;
    this.rawPcmData = [];            // 生のPCMデータ (Float32Arrayの配列) をここに蓄積
    this.sampleRate = null;          // AudioContextから取得
    this.latestRecordingBlob = null; // 送信用のWAV Blob
    this.recordingTimer = null;      // 録音時間表示用のタイマーID
    this.recordingStartTime = null;  // 録音開始時刻
    // this.maxRecordingTime = 5000;    // 録音時間上限 (ミリ秒単位、例: 5秒)
    this.autoStopTimer = null;       // 自動停止用タイマーID

    this.updateButtonStates();       // 初期ボタン状態設定
  }

  // ボタンの表示/非表示と有効/無効を切り替えるヘルパー
  updateButtonStates() {
    if (this.hasStartButtonTarget) {
      this.startButtonTarget.classList.toggle("hidden", this.isRecording);
      this.startButtonTarget.disabled = this.isRecording;
    }
    if (this.hasStopButtonTarget) {
      this.stopButtonTarget.classList.toggle("hidden", !this.isRecording);
      this.stopButtonTarget.disabled = !this.isRecording;
    }
  }

  // マイクへのアクセス許可を要求する
  async requestMicrophoneAccess() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true, video: false });
      if (this.hasStatusTarget) this.statusTarget.textContent = "マイクアクセス許可済み";
      return stream;
    } catch (err) {
      console.error("マイクへのアクセス許可が得られませんでした:", err);
      let message = "エラー: マイクへのアクセスが拒否されました。";
      if (err.name === 'NotFoundError' || err.name === 'DevicesNotFoundError') {
        message = "エラー: 利用可能なマイクが見つかりませんでした。";
      } else if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') {
        message = "エラー: マイクへのアクセス許可がありません。ブラウザの設定を確認してください。";
      }
      if (this.hasStatusTarget) this.statusTarget.textContent = message;
      if (this.hasStartButtonTarget) this.startButtonTarget.disabled = true; // エラー時は開始ボタンを無効化
      return null;
    }
  }

  // 録音開始処理
  async startRecording() {
    if (this.isRecording) return;

    const stream = await this.requestMicrophoneAccess();
    if (!stream) return;

    // 以前のAudioContextが残っていれば閉じる (安全のため)
    if (this.audioContext && this.audioContext.state !== 'closed') {
      await this.audioContext.close().catch(e => console.warn("Previous AudioContext close error:", e));
    }

    this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
    this.sampleRate = this.audioContext.sampleRate;
    this.mediaStreamSource = this.audioContext.createMediaStreamSource(stream);
    this.rawPcmData = []; // 録音データ配列を初期化
    this.latestRecordingBlob = null; // Blobも初期化
    if (this.hasPlaybackAreaTarget) this.playbackAreaTarget.innerHTML = ''; // 古い再生UIをクリア

    try {
      // Audio Worklet Processor のパス (public配下に配置した場合)
      const workletURL = '/audio_worklets/recorder-processor.js';
      await this.audioContext.audioWorklet.addModule(workletURL);

      this.audioWorkletNode = new AudioWorkletNode(this.audioContext, 'recorder-processor', {
        processorOptions: {
          bufferSize: 16384, // Workletからメインスレッドに送るPCMデータのチャンクサイズ (サンプル数)
          channelCount: 1    // モノラル録音
        }
      });

      this.audioWorkletNode.port.onmessage = (event) => {
        if (event.data.type === 'audioData') {
          // event.data.buffer は ArrayBuffer なので、Float32Arrayに戻す
          this.rawPcmData.push(new Float32Array(event.data.buffer));
        } else if (event.data.type === 'status' && event.data.message === 'stopped') {
          console.log("Worklet has stopped and flushed remaining data.");
        }
      };

      this.mediaStreamSource.connect(this.audioWorkletNode);
      // this.audioWorkletNode.connect(this.audioContext.destination); // 通常、音声出力は不要

      this.audioWorkletNode.port.postMessage({ command: 'start' }); // Workletに録音開始を通知
      this.isRecording = true;

      this.updateButtonStates();
      this.recordingStartTime = Date.now();
      this.updateRecordingTime(); // タイマー表示開始
      if (this.hasStatusTarget) this.statusTarget.textContent = "録音中... 00:00";
      console.log("AudioWorkletNode setup complete, recording started at sample rate:", this.sampleRate);

      // ★ 5秒後に自動停止するタイマーを設定
      if (this.autoStopTimer) clearTimeout(this.autoStopTimer); // 既存のタイマーがあればクリア
      this.autoStopTimer = setTimeout(() => {
        if (this.isRecording) { // まだ録音中であれば停止する
          console.log("5秒経過、自動停止します。");
          this.stopRecording();
        }
      }, 5000);

    } catch (err) {
      console.error("AudioWorkletのセットアップまたは録音開始に失敗しました:", err);
      if (this.hasStatusTarget) this.statusTarget.textContent = "エラー: 録音を開始できませんでした。";
      if (stream) stream.getTracks().forEach(track => track.stop()); // マイクストリームを停止
      if (this.audioContext && this.audioContext.state !== 'closed') {
        this.audioContext.close();
      }
      this.isRecording = false; // 状態をリセット
      this.updateButtonStates(); // ボタンの状態を戻す
      if (this.autoStopTimer) clearTimeout(this.autoStopTimer); // エラー時もタイマーをクリア
    }
  }

  // 録音停止処理
  async stopRecording() {
    if (!this.isRecording) return;
    if (this.autoStopTimer) clearTimeout(this.autoStopTimer); // 自動停止タイマーをクリア
    this.isRecording = false; // まずisRecordingフラグをfalseに
    if (this.recordingTimer) clearInterval(this.recordingTimer); // タイマー停止

    if (this.hasStatusTarget) this.statusTarget.textContent = "録音停止、音声データを処理中...";
    this.updateButtonStates(); // ボタン状態を更新 (開始ボタン表示、停止ボタン非表示)

    if (this.audioWorkletNode) {
      this.audioWorkletNode.port.postMessage({ command: 'stop' }); // Workletに停止を通知
    }

    // マイクストリームのトラックを停止してマイクを解放
    if (this.mediaStreamSource && this.mediaStreamSource.mediaStream) {
      this.mediaStreamSource.mediaStream.getTracks().forEach(track => track.stop());
    }
    // オーディオノードの接続を解除
    if (this.mediaStreamSource && this.audioWorkletNode) {
      try { this.mediaStreamSource.disconnect(this.audioWorkletNode); } catch(e) { console.warn("Error disconnecting mediaStreamSource:", e); }
    }
    // AudioWorkletNode自体の接続解除 (AudioContextを閉じる前に)
    if (this.audioWorkletNode && this.audioContext && this.audioContext.destination) {
      // もしパススルーでdestinationに繋いでいたらそれもdisconnect
      // try { this.audioWorkletNode.disconnect(this.audioContext.destination); } catch(e) { console.warn("Error disconnecting audioWorkletNode from destination:", e); }
    }
    this.audioWorkletNode = null;
    this.mediaStreamSource = null;

    // AudioContextを閉じるのは非同期なので、完了を待ってからデータ処理
    if (this.audioContext && this.audioContext.state !== 'closed') {
      try {
        await this.audioContext.close();
        console.log("AudioContext closed successfully.");
      } catch (e) {
        console.error("Error closing AudioContext:", e);
      }
    }
    this.audioContext = null;

    // Workletからの最後のデータが届くのを少し待つ
    // (より堅牢にするならWorkletからの 'stopped' メッセージ受信をトリガーにする)
    setTimeout(() => {
      this.processRecordedData(); // WAVエンコードと再生UI作成
      // processRecordedData の中で this.latestRecordingBlob がセットされるので、その後に送信
      if (this.latestRecordingBlob) {
        this.sendAudioData(this.latestRecordingBlob);
      } else {
        console.warn("送信する録音データがありません。");
        if (this.hasStatusTarget) this.statusTarget.textContent = "送信する録音データがありませんでした。";
      }
    }, 200); // 200ms待機 (この時間は調整が必要な場合あり)
  }

  // 録音されたPCMデータをWAVにエンコードし、再生UIを作成
  processRecordedData() {
    if (this.rawPcmData.length === 0) {
      console.warn("録音データがありません。");
      if (this.hasStatusTarget) this.statusTarget.textContent = "録音データがありませんでした。";
      return;
    }

    // 全てのPCMデータチャンクを一つのFloat32Arrayに結合
    let totalLength = 0;
    this.rawPcmData.forEach(chunk => { totalLength += chunk.length; });
    const pcmData = new Float32Array(totalLength);
    let offset = 0;
    this.rawPcmData.forEach(chunk => {
      pcmData.set(chunk, offset);
      offset += chunk.length;
    });

    // WAV形式にエンコード
    const wavBlob = this.encodePcmToWav(pcmData, this.sampleRate);
    this.latestRecordingBlob = wavBlob; // 後で送信するために保持

    // 再生用UIの作成
    if (this.hasPlaybackAreaTarget) this.playbackAreaTarget.innerHTML = ''; // 古い再生UIをクリア
    if (wavBlob && wavBlob.size > 44) { // ヘッダだけの空ファイルでないことを確認
      const audioUrl = URL.createObjectURL(wavBlob);
      const audioElement = new Audio(audioUrl);
      audioElement.controls = true;
      if (this.hasPlaybackAreaTarget) this.playbackAreaTarget.appendChild(audioElement);
      if (this.hasStatusTarget) this.statusTarget.textContent = "録音完了！再生できます。";
    } else {
      if (this.hasStatusTarget) this.statusTarget.textContent = "録音に失敗したか、音声が短すぎます。";
    }

    this.rawPcmData = []; // 次の録音のためにクリア
    console.log("WAV Blob created:", wavBlob);
  }

  async sendAudioData(blob) {
    if (!blob || blob.size <= 44) { // 44はWAVヘッダのみのサイズ
      console.warn("有効な録音データがないため送信をスキップします。");
      if (this.hasStatusTarget) this.statusTarget.textContent = "有効な録音データがありませんでした。";
      return;
    }

    if (this.hasStatusTarget) this.statusTarget.textContent = "音声データを送信中...";
    console.log("Sending audio data to Rails:", blob);

    const formData = new FormData();
    // Rails側で params[:voice_condition_log][:recorded_audio] として受け取る
    formData.append("voice_condition_log[recorded_audio]", blob, "recording.wav");
    // Rails側で params[:voice_condition_log][:phrase_text_snapshot] として受け取る
    // お題フレーズをビューから取得するか、コントローラーから渡されたものを保持しておく必要がある
    // ここでは、ビューの特定要素から取得する例 (data属性などを使うと良い)
    const phraseElement = document.getElementById("current-phrase"); // 仮のID
    const phraseText = phraseElement ? phraseElement.textContent : "（お題不明）";
    formData.append("voice_condition_log[phrase_text_snapshot]", phraseText);


    // CSRFトークンの取得
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content;
    if (!csrfToken) {
      console.error("CSRF token not found!");
      if (this.hasStatusTarget) this.statusTarget.textContent = "エラー: 送信に失敗しました (CSRFトークンが見つかりません)。";
      return;
    }

    try {
      const response = await fetch("/voice_condition_logs", { // VoiceConditionLogsController#create へのパス
        method: "POST",
        headers: {
          "X-CSRF-Token": csrfToken
        },
        body: formData
      });

      if (response.ok) {
        console.log("音声データ送信成功。レスポンス:", response);
        // response.url は fetch がリダイレクトに追従した場合、最終的なURL (showページのURL) を指します。
        // response.redirected は、リダイレクトが発生したかどうかを示します。
        if (this.hasStatusTarget) this.statusTarget.textContent = "送信成功！結果ページに移動します...";

        if (response.redirected) {
          // fetchがリダイレクトに追従した場合、response.urlがリダイレクト後のURL
          window.location.href = response.url;
        } else {
          // もしリダイレクトが発生せず、かつレスポンスがOKだった場合
          // (通常、Railsの create -> redirect_to のパターンではここは通らないはずだが、念のため)
          // もし response.url が期待通りでなければ、ここで何らかのフォールバックやエラー表示が必要。
          console.warn("リダイレクトが発生しませんでしたが、レスポンスはOKでした。URL:", response.url);
        }
      } else {
        console.error("音声データ送信失敗:", response);
        const errorText = await response.text(); // エラーレスポンスのボディを取得
        console.error("エラー詳細:", errorText);  // サーバーからのHTMLエラーページなどがここに入る
        if (this.hasStatusTarget) this.statusTarget.textContent = `エラー： 送信に失敗しました (${response.status})。ページをリロードしてください。`;
      }
    } catch (error) {
      console.error("音声データ送信中にネットワークエラー等が発生しました:", error);
      if (this.hasStatusTarget) this.statusTarget.textContent = "エラー： 送信中に問題が発生しました。";
    }
  }

  // 録音時間のUIを更新
  updateRecordingTime() {
    if (!this.isRecording || !this.recordingStartTime) {
      if (this.recordingTimer) clearInterval(this.recordingTimer);
      return;
    }
    this.recordingTimer = setInterval(() => {
      if (!this.isRecording) { // isRecordingがfalseになったらタイマーを止める
        clearInterval(this.recordingTimer);
        return;
      }
      const elapsedTime = Math.floor((Date.now() - this.recordingStartTime) / 1000);
      const minutes = Math.floor(elapsedTime / 60).toString().padStart(2, '0');
      const seconds = (elapsedTime % 60).toString().padStart(2, '0');
      if (this.hasStatusTarget) this.statusTarget.textContent = `録音中... ${minutes}:${seconds}`;
    }, 1000);
  }

  // --- WAVエンコードヘルパー関数 ---
  encodePcmToWav(samples, sampleRate) {
    const numChannels = 1; // モノラル
    const bitsPerSample = 16; // 16ビットPCM

    const blockAlign = (numChannels * bitsPerSample) / 8;
    const byteRate = sampleRate * blockAlign;
    const dataSize = samples.length * (bitsPerSample / 8);

    // WAVヘッダのサイズ (44バイト)
    const headerSize = 44;
    const buffer = new ArrayBuffer(headerSize + dataSize);
    const view = new DataView(buffer);

    // RIFFチャンク
    this.writeString(view, 0, 'RIFF');
    view.setUint32(4, 36 + dataSize, true); // ファイルサイズ - 8バイト
    this.writeString(view, 8, 'WAVE');

    // fmtチャンク
    this.writeString(view, 12, 'fmt ');
    view.setUint32(16, 16, true); // fmtチャンクのサイズ (PCMの場合)
    view.setUint16(20, 1, true);  // AudioFormat (PCM=1)
    view.setUint16(22, numChannels, true);
    view.setUint32(24, sampleRate, true);
    view.setUint32(28, byteRate, true);
    view.setUint16(32, blockAlign, true);
    view.setUint16(34, bitsPerSample, true);

    // dataチャンク
    this.writeString(view, 36, 'data');
    view.setUint32(40, dataSize, true);

    // PCMデータを16ビット符号付き整数に変換して書き込み
    this.floatTo16BitPCM(view, 44, samples);

    return new Blob([view], { type: 'audio/wav' });
  }

  writeString(view, offset, string) {
    for (let i = 0; i < string.length; i++) {
      view.setUint8(offset + i, string.charCodeAt(i));
    }
  }

  floatTo16BitPCM(output, offset, input) {
    for (let i = 0; i < input.length; i++, offset += 2) {
      const s = Math.max(-1, Math.min(1, input[i])); // -1から1の範囲にクリップ
      output.setInt16(offset, s < 0 ? s * 0x8000 : s * 0x7FFF, true); // 16ビット整数に変換
    }
  }
  // --- ここまでWAVエンコードヘルパー ---

  disconnect() {
    // StimulusコントローラーがDOMから除去されるときに呼ばれる
    if (this.isRecording) {
      this.stopRecording(); // 念のため録音を停止
    }
    if (this.recordingTimer) clearInterval(this.recordingTimer);
    console.log("WebAudioRecorderController disconnected");
  }
}