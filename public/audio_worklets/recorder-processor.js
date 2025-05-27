class RecorderProcessor extends AudioWorkletProcessor {
  constructor(options) {
    super(options);
    this._bufferSize = options.processorOptions.bufferSize || 16384; // チャンクサイズ
    this._channelCount = options.processorOptions.channelCount || 1;
    this._recording = false;
    this._internalBuffer = [];
    this._bytesWritten = 0;

    this.port.onmessage = (event) => {
      if (event.data.command === 'start') {
        this._recording = true;
        this._internalBuffer = [];
        this._bytesWritten = 0;
      } else if (event.data.command === 'stop') {
        this._recording = false;
        if (this._internalBuffer.length > 0) {
          this.flushBuffer();
        }
        this.port.postMessage({ type: 'status', message: 'stopped' });
      }
    };
  }

  process(inputs, outputs, parameters) {
    if (!this._recording) return true;
    const inputChannelData = inputs[0]?.[0]; // Optional chaining for safety

    if (inputChannelData && inputChannelData.length > 0) {
      this._internalBuffer.push(new Float32Array(inputChannelData));
      this._bytesWritten += inputChannelData.length;

      let currentBufferedSamples = 0;
      this._internalBuffer.forEach(buf => currentBufferedSamples += buf.length);

      if (currentBufferedSamples >= this._bufferSize) {
        this.flushBuffer();
      }
    }
    return true;
  }

  flushBuffer() {
    if (this._internalBuffer.length === 0) return;
    let totalLength = 0;
    this._internalBuffer.forEach(buffer => totalLength += buffer.length);
    const result = new Float32Array(totalLength);
    let offset = 0;
    this._internalBuffer.forEach(buffer => {
      result.set(buffer, offset);
      offset += buffer.length;
    });
    this.port.postMessage({ type: 'audioData', buffer: result.buffer }, [result.buffer]);
    this._internalBuffer = [];
  }
}
registerProcessor('recorder-processor', RecorderProcessor);