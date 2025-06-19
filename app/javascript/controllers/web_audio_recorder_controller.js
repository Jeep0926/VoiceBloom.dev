// app/javascript/controllers/web_audio_recorder_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // 1. デザインに合わせてターゲットを追加
  static targets = [
    "startButton",          // 「録音を開始する」ボタン
    "stopButton",           // 「録音を停止する」ボタン
    "statusText",           // 状態表示用のテキストエリア (任意)
    "playbackArea",         // 録音後の再生プレイヤー表示エリア (任意)
    "sampleAudioButton",    // 「お手本を聴く」ボタン
    "sampleAudioPlayer",    // <audio>タグのお手本プレイヤー (通常は非表示)
    "recordIndicatorIcon",  // 録音状態を示す中央のアイコン (マイク/波形)
    "recordIndicatorText",  // 録音状態を示す中央下のテキスト
    "micIcon",              // マイクのアイコン
    "recorder",             // 録音UI全体を囲むコンテナ
    "result",               // 評価結果UI全体を囲むコンテナ
    "nextButton",           // 「次へ進む」ボタン
    "finishButton"          // 「結果をみる」ボタン
  ]

  // 2. ビューから値を受け取るためのValueを追加
  static values = {
    postUrl: String,           // データの送信先URL
    formFieldName: String,     // フォームデータに含める音声データのキー名
    sendPhraseSnapshot: { type: Boolean, default: true }, // デフォルトは送信する
    exerciseId: String,     // お題のID（フォームデータ作成時に2問目以降が表示されるために必要）
    attemptNumber: Number,
    finishUrl: String
  }

  // --- プロパティの初期化 ---
  initialize() {
    this.isRecording = false
    this.isSamplePlaying = false
    this.audioContext = null
    this.mediaStreamSource = null
    this.audioWorkletNode = null
    this.rawPcmData = []
    this.sampleRate = null
    this.latestRecordingBlob = null
    this.recordingTimer = null
    this.recordingStartTime = null
    this.autoStopTimer = null
  }

  // --- Stimulusコントローラー接続時の処理 ---
  connect() {
    console.log("WebAudioRecorderController connected!");
    this.resetUI(); // 初期UI表示を確実にする

    // お手本音声プレイヤーの再生・停止イベントを監視してボタンのテキストを更新
    if (this.hasSampleAudioPlayerTarget) {
      this.sampleAudioPlayerTarget.onplay = () => {
        this.isSamplePlaying = true;
        // ★ 修正：ターゲット名が sampleAudioButtonTarget なので、プロパティも合わせる
        if (this.hasSampleAudioButtonTarget) {
          this.sampleAudioButtonTarget.innerHTML = `
            <span class="inline-flex items-center justify-center">
              <svg class="h-5 w-5 mr-2 animate-spin" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
              再生中...
            </span>
          `;
        }
      };
      this.sampleAudioPlayerTarget.onpause = () => {
        this.isSamplePlaying = false;
        // ★ 修正：ターゲット名が sampleAudioButtonTarget なので、プロパティも合わせる
        if (this.hasSampleAudioButtonTarget) {
          this.sampleAudioButtonTarget.innerHTML = `
            <span class="inline-flex items-center justify-center">
              <svg class="h-5 w-5 mr-2" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M19.114 5.636a9 9 0 010 12.728M16.463 8.288a5.25 5.25 0 010 7.424M6.75 8.25l4.72-4.72a.75.75 0 011.28.53v15.88a.75.75 0 01-1.28.53l-4.72-4.72H4.51c-.88 0-1.704-.507-1.938-1.354A9.01 9.01 0 012.25 12c0-.83.112-1.633.322-2.396C2.806 8.756 3.63 8.25 4.51 8.25H6.75z" /></svg>
              お手本を聴く
            </span>
          `;
        }
        this.sampleAudioPlayerTarget.currentTime = 0;
      };
    }
  }

  // --- お手本音声を再生するアクション ---
  playSampleAudio() {
    if (!this.hasSampleAudioPlayerTarget || this.isRecording) return;

    if (this.sampleAudioPlayerTarget.paused) {
      this.sampleAudioPlayerTarget.play();
    } else {
      this.sampleAudioPlayerTarget.pause();
    }
  }

  // 録音開始・停止処理にUI更新ロジックを統合

  disconnect() {
    if (this.isRecording) { this.stopRecording(); }
    if (this.recordingTimer) clearInterval(this.recordingTimer);
    if (this.autoStopTimer) clearTimeout(this.autoStopTimer);
    console.log("WebAudioRecorderController disconnected.");
  }

  updateButtonStates() {
    if (this.hasStartButtonTarget) this.startButtonTarget.classList.toggle("hidden", this.isRecording);
    if (this.hasStopButtonTarget) this.stopButtonTarget.classList.toggle("hidden", !this.isRecording);
  }

  setRecordingUI() {
    this.isRecording = true;
    this.updateButtonStates();
    if (this.hasRecordIndicatorIconTarget) this.recordIndicatorIconTarget.innerHTML = this.recordingIconTemplate();
    if (this.hasRecordIndicatorTextTarget) this.recordIndicatorTextTarget.textContent = "録音中 0 / 5 秒";
    this.updateRecordingTime();
  }

  resetUI() {
    this.isRecording = false;
    this.updateButtonStates();
    // if (this.hasRecordIndicatorIconTarget) this.recordIndicatorIconTarget.innerHTML = this.micIconTemplate();
    if (this.hasRecordIndicatorTextTarget) this.recordIndicatorTextTarget.textContent = "タップして録音開始";
    if (this.hasStatusTextTarget) this.statusTextTarget.textContent = "";
    if (this.hasPlaybackAreaTarget) this.playbackAreaTarget.innerHTML = "";
  }

  updateRecordingTime() {
    if (this.recordingTimer) clearInterval(this.recordingTimer);
    this.recordingTimer = setInterval(() => {
      if (!this.isRecording) {
        clearInterval(this.recordingTimer);
        return;
      }
      const elapsedTime = Math.floor((Date.now() - this.recordingStartTime) / 1000);
      if (this.hasRecordIndicatorTextTarget) this.recordIndicatorTextTarget.textContent = `録音中 ${elapsedTime} / 5 秒`;
    }, 1000);
  }

  // ★ 5. 録音開始・停止処理にUI更新ロジックを統合
  async startRecording() {
    if (this.isRecording || this.isSamplePlaying) return; // お手本再生中も録音開始しない

    const stream = await this.requestMicrophoneAccess();
    if (!stream) return;

    if (this.audioContext && this.audioContext.state !== 'closed') {
      await this.audioContext.close();
    }

    this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
    this.sampleRate = this.audioContext.sampleRate;
    this.mediaStreamSource = this.audioContext.createMediaStreamSource(stream);
    this.rawPcmData = [];
    this.latestRecordingBlob = null;

    try {
      const workletURL = '/audio_worklets/recorder-processor.js';
      await this.audioContext.audioWorklet.addModule(workletURL);

      this.audioWorkletNode = new AudioWorkletNode(this.audioContext, 'recorder-processor', {
        processorOptions: { bufferSize: 16384, channelCount: 1 }
      });

      this.audioWorkletNode.port.onmessage = (event) => {
        if (event.data.type === 'audioData') {
          this.rawPcmData.push(new Float32Array(event.data.buffer));
        }
      };

      this.mediaStreamSource.connect(this.audioWorkletNode);
      this.audioWorkletNode.port.postMessage({ command: 'start' });

      this.recordingStartTime = Date.now();
      this.setRecordingUI(); // UIを「録音中」状態に更新

      this.autoStopTimer = setTimeout(() => {
        if (this.isRecording) this.stopRecording();
      }, 5000);

    } catch (err) {
      console.error("録音開始に失敗しました:", err);
      if (this.hasRecordIndicatorTextTarget) this.recordIndicatorTextTarget.textContent = "エラー: 録音を開始できませんでした。";
      if (stream) stream.getTracks().forEach(track => track.stop());
      this.resetUI();
    }
  }

  async stopRecording() {
    if (!this.isRecording) return;

    // UIの即時フィードバック
    if (this.hasRecordIndicatorTextTarget) this.recordIndicatorTextTarget.textContent = "録音停止、データを処理中...";
    // タイマー類をクリア
    if (this.autoStopTimer) clearTimeout(this.autoStopTimer);
    if (this.recordingTimer) clearInterval(this.recordingTimer);

    this.isRecording = false; // フラグを更新

    if (this.audioWorkletNode) {
      this.audioWorkletNode.port.postMessage({ command: 'stop' });
    }
    if (this.mediaStreamSource && this.mediaStreamSource.mediaStream) {
      this.mediaStreamSource.mediaStream.getTracks().forEach(track => track.stop());
    }
    if (this.mediaStreamSource && this.audioWorkletNode) {
      try { this.mediaStreamSource.disconnect(this.audioWorkletNode); } catch(e) {}
    }
    this.audioWorkletNode = null;
    this.mediaStreamSource = null;

    if (this.audioContext && this.audioContext.state !== 'closed') {
      await this.audioContext.close();
    }
    this.audioContext = null;

    setTimeout(() => {
      this.processRecordedData();
      if (this.latestRecordingBlob) {
        this.sendAudioData(this.latestRecordingBlob);
      } else {
        if (this.hasRecordIndicatorTextTarget) this.recordIndicatorTextTarget.textContent = "録音データがありませんでした。";
        this.resetUI();
      }
    }, 200);
  }

  // ★ 6. データ送信ロジックを汎用化
  async sendAudioData(blob) {
    if (!this.hasPostUrlValue || !this.hasFormFieldNameValue) {
      console.error("送信先URLまたはフォーム名が設定されていません。"); this.resetUI(); return;
    }
    if (this.hasRecordIndicatorTextTarget) this.recordIndicatorTextTarget.textContent = "音声データを送信・分析中...";
    this.stopButtonTarget.disabled = true;

    const formData = new FormData();
    formData.append(this.formFieldNameValue, blob, "recording.wav");
    if (this.hasExerciseIdValue) {
      const exerciseIdKey = this.formFieldNameValue.replace(/\[recorded_audio\]$/, '[practice_exercise_id]');
      formData.append(exerciseIdKey, this.exerciseIdValue);
    }
    if (this.sendPhraseSnapshotValue) {
      const phraseElement = document.getElementById("current-phrase");
      if (phraseElement) {
        const snapshotKey = this.formFieldNameValue.replace(/\[recorded_audio\]$/, '[phrase_text_snapshot]');
        formData.append(snapshotKey, phraseElement.textContent.trim());
      }
    }

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content;
    if (!csrfToken) { this.resetUI(); return; }

    try {
      const response = await fetch(this.postUrlValue, {
        method: "POST",
        headers: { "X-CSRF-Token": csrfToken, "Accept": "application/json" }, 
        body: formData
      });
      const data = await response.json();

      if (response.ok) {
        // レスポンスの形式によって処理を分岐
        if (data.redirect_url) {
          // 声のコンディション確認機能の場合：リダイレクト先URLが返ってくる
          window.location.href = data.redirect_url;
        } else if (data.result_html) {
          // 発声練習機能の場合：結果表示用のHTMLが返ってくる
          this.recorderTarget.classList.add("hidden");
          this.resultTarget.innerHTML = data.result_html;
          this.resultTarget.classList.remove("hidden");

          if (data.next_action.button_type === 'next') {
            this.nextButtonTarget.href = data.next_action.url;
            this.nextButtonTarget.classList.remove('hidden');
          } else if (data.next_action.button_type === 'finish') {
            this.finishButtonTarget.href = data.next_action.url;
            this.finishButtonTarget.classList.remove('hidden');
          }
        }
      } else {
        this.resetUI();
        if (this.hasRecordIndicatorTextTarget) this.recordIndicatorTextTarget.textContent = `エラー： ${data.errors?.join(', ') || '送信に失敗しました'}`;
      }
    } catch (error) {
      this.resetUI();
      if (this.hasRecordIndicatorTextTarget) this.recordIndicatorTextTarget.textContent = "エラー： 通信中に問題が発生しました。";
    }
  }

  recordingIconTemplate() {
    return `<svg class="h-16 w-16 text-purple-600 animate-pulse" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
    </svg>`;
  }

  processRecordedData() {
    if (this.rawPcmData.length === 0) { console.warn("録音データがありません。"); return; }
    let totalLength = 0;
    this.rawPcmData.forEach(chunk => { totalLength += chunk.length; });
    const pcmData = new Float32Array(totalLength);
    let offset = 0;
    this.rawPcmData.forEach(chunk => { pcmData.set(chunk, offset); offset += chunk.length; });
    const wavBlob = this.encodePcmToWav(pcmData, this.sampleRate);
    this.latestRecordingBlob = wavBlob;
    this.rawPcmData = [];
  }

  encodePcmToWav(samples, sampleRate) {
    const buffer = new ArrayBuffer(44 + samples.length * 2);
    const view = new DataView(buffer);
    this.writeString(view, 0, 'RIFF');
    view.setUint32(4, 36 + samples.length * 2, true);
    this.writeString(view, 8, 'WAVE');
    this.writeString(view, 12, 'fmt ');
    view.setUint32(16, 16, true);
    view.setUint16(20, 1, true);
    view.setUint16(22, 1, true);
    view.setUint32(24, sampleRate, true);
    view.setUint32(28, sampleRate * 2, true);
    view.setUint16(32, 2, true);
    view.setUint16(34, 16, true);
    this.writeString(view, 36, 'data');
    view.setUint32(40, samples.length * 2, true);
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
      const s = Math.max(-1, Math.min(1, input[i]));
      output.setInt16(offset, s < 0 ? s * 0x8000 : s * 0x7FFF, true);
    }
  }
  
  async requestMicrophoneAccess() {
    try {
      return await navigator.mediaDevices.getUserMedia({ audio: true, video: false });
    } catch (err) {
      console.error("マイクへのアクセス許可が得られませんでした:", err);
      if (this.hasRecordIndicatorTextTarget) {
        this.recordIndicatorTextTarget.textContent = "エラー：マイクへのアクセスが拒否されました。";
      }
      return null;
    }
  }
}