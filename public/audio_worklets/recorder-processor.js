// public/audio_worklets/recorder-processor.js
class RecorderProcessor extends AudioWorkletProcessor {
  constructor(options) {
    super();
    
    this.bufferSize = options.processorOptions?.bufferSize || 16384;
    this.channelCount = options.processorOptions?.channelCount || 1;
    this.buffer = new Float32Array(this.bufferSize);
    this.bufferIndex = 0;
    this.isRecording = false;
    
    this.port.onmessage = (event) => {
      if (event.data.command === 'start') {
        this.isRecording = true;
        console.log('RecorderProcessor: Recording started');
      } else if (event.data.command === 'stop') {
        this.isRecording = false;
        this.flushBuffer();
        console.log('RecorderProcessor: Recording stopped');
        this.port.postMessage({ type: 'status', message: 'stopped' });
      }
    };
  }
  
  process(inputs, outputs, parameters) {
    if (!this.isRecording) {
      return true;
    }
    
    const input = inputs[0];
    if (input && input.length > 0) {
      const inputChannel = input[0]; // モノラル録音のため最初のチャンネルのみ使用
      
      for (let i = 0; i < inputChannel.length; i++) {
        this.buffer[this.bufferIndex] = inputChannel[i];
        this.bufferIndex++;
        
        // バッファが満杯になったらメインスレッドに送信
        if (this.bufferIndex >= this.bufferSize) {
          this.flushBuffer();
        }
      }
    }
    
    return true; // プロセッサーを継続
  }
  
  flushBuffer() {
    if (this.bufferIndex > 0) {
      // バッファに蓄積されたデータをメインスレッドに送信
      const dataToSend = this.buffer.slice(0, this.bufferIndex);
      this.port.postMessage({
        type: 'audioData',
        buffer: dataToSend.buffer.slice(0, this.bufferIndex * 4) // Float32Arrayなので4倍
      });
      
      this.bufferIndex = 0; // バッファをリセット
    }
  }
}

registerProcessor('recorder-processor', RecorderProcessor);