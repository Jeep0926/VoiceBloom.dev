from fastapi import FastAPI, File, UploadFile
from typing import Annotated
import shutil
import os
import librosa
import numpy as np
import scipy.signal
from schemas import VoiceFeaturesResponse

app = FastAPI()


@app.get("/health")
async def health_check():
    return {"status": "ok"}


TEMP_AUDIO_DIR = "temp_audio_files"


@app.on_event("startup")
async def startup_event():
    os.makedirs(TEMP_AUDIO_DIR, exist_ok=True)


def extract_voice_segments(y, sr, min_duration=0.1):
    """
    高速な音声区間検出
    短時間エネルギーベースで音声区間を特定
    """
    # フレームサイズを大きくして処理速度向上
    frame_length = 2048
    hop_length = 512

    # 短時間エネルギー計算
    energy = librosa.feature.rms(y=y, frame_length=frame_length, hop_length=hop_length)[
        0
    ]

    # エネルギーの閾値を動的に設定（最大エネルギーの5%）
    threshold = np.max(energy) * 0.05

    # 音声区間の検出
    voice_frames = energy > threshold

    # フレームを時間に変換
    times = librosa.frames_to_time(
        np.arange(len(voice_frames)), sr=sr, hop_length=hop_length
    )

    # 連続する音声区間をまとめる
    voice_segments = []
    start_time = None

    for i, is_voice in enumerate(voice_frames):
        if is_voice and start_time is None:
            start_time = times[i]
        elif not is_voice and start_time is not None:
            end_time = times[i]
            if end_time - start_time >= min_duration:
                voice_segments.append((start_time, end_time))
            start_time = None

    # 最後の区間の処理
    if start_time is not None:
        end_time = times[-1]
        if end_time - start_time >= min_duration:
            voice_segments.append((start_time, end_time))

    return voice_segments


def analyze_pitch_fast(y, sr):
    """
    高速ピッチ分析
    autocorrelationベースの高速F0推定
    """
    try:
        # フレームサイズを調整して処理速度向上
        frame_length = 2048
        hop_length = 512

        # 音声を短時間フレームに分割
        frames = librosa.util.frame(y, frame_length=frame_length, hop_length=hop_length)

        pitches = []

        for frame in frames.T:
            # 各フレームで自己相関を計算
            autocorr = np.correlate(frame, frame, mode="full")
            autocorr = autocorr[len(autocorr) // 2 :]

            # 基本周波数の範囲を制限（50-400Hz）
            min_period = int(sr / 400)  # 最高周波数に対応する最小周期
            max_period = int(sr / 50)  # 最低周波数に対応する最大周期

            if len(autocorr) > max_period:
                # 指定範囲内でピークを検出
                search_range = autocorr[min_period:max_period]
                if len(search_range) > 0:
                    peak_idx = np.argmax(search_range) + min_period
                    if autocorr[peak_idx] > 0.3 * autocorr[0]:  # 閾値による有効性判定
                        f0 = sr / peak_idx
                        if 50 <= f0 <= 400:
                            pitches.append(f0)

        return np.median(pitches) if pitches else None

    except Exception as e:
        print(f"Pitch analysis error: {e}")
        return None


def analyze_tempo_fast(y, sr, voice_segments):
    """
    高速テンポ分析
    簡素化されたonset検出
    """
    try:
        if not voice_segments:
            return None, 0, 0

        total_speech_time = sum(end - start for start, end in voice_segments)

        # 音声区間のみを抽出
        voice_audio = []
        for start, end in voice_segments:
            start_sample = int(start * sr)
            end_sample = int(end * sr)
            voice_audio.extend(y[start_sample:end_sample])

        if not voice_audio:
            return None, 0, 0

        voice_audio = np.array(voice_audio)

        # スペクトラル流束を使用した高速onset検出
        stft = librosa.stft(voice_audio, hop_length=512)
        spectral_flux = np.sum(np.diff(np.abs(stft), axis=1) > 0, axis=0)

        # ピーク検出でonsetを見つける
        peaks, _ = scipy.signal.find_peaks(
            spectral_flux,
            height=np.max(spectral_flux) * 0.3,
            distance=int(0.1 * sr / 512),
        )

        onset_count = len(peaks)

        if total_speech_time > 0:
            syllables_per_minute = (onset_count / total_speech_time) * 60
            return syllables_per_minute, total_speech_time, onset_count

        return None, 0, 0

    except Exception as e:
        print(f"Tempo analysis error: {e}")
        return None, 0, 0


def analyze_volume_advanced(y, sr, voice_segments):
    """
    高度な音量分析
    音声区間のみでの複数指標計算
    """
    try:
        if not voice_segments:
            return None, None, None

        # 音声区間のみを抽出
        voice_audio = []
        for start, end in voice_segments:
            start_sample = int(start * sr)
            end_sample = int(end * sr)
            voice_audio.extend(y[start_sample:end_sample])

        if not voice_audio:
            return None, None, None

        voice_audio = np.array(voice_audio)

        # 1. dBFS (実際の音声部分のみ)
        rms_energy = np.sqrt(np.mean(voice_audio**2))
        dbfs = 20 * np.log10(rms_energy) if rms_energy > 0 else None

        # 2. LUFS (Loudness Units relative to Full Scale) の簡易版
        # 周波数重み付けフィルタの近似
        b, a = scipy.signal.butter(2, [500, 2000], btype="band", fs=sr)
        filtered_audio = scipy.signal.filtfilt(b, a, voice_audio)
        lufs_rms = np.sqrt(np.mean(filtered_audio**2))
        # K-weighting近似
        lufs = 20 * np.log10(lufs_rms) - 0.691 if lufs_rms > 0 else None

        # 3. 動的レンジ (dB)
        percentile_95 = np.percentile(np.abs(voice_audio), 95)
        percentile_10 = np.percentile(np.abs(voice_audio), 10)
        dynamic_range = (
            20 * np.log10(percentile_95 / percentile_10) if percentile_10 > 0 else None
        )

        return dbfs, lufs, dynamic_range

    except Exception as e:
        print(f"Volume analysis error: {e}")
        return None, None, None


@app.post("/analyze/voice_condition", response_model=VoiceFeaturesResponse)
async def analyze_voice_condition(file: Annotated[UploadFile, File()]):
    if not file:
        return VoiceFeaturesResponse(analysis_error_message="No file sent")

    filename = file.filename or "uploaded_audio.wav"
    temp_file_path = os.path.join(TEMP_AUDIO_DIR, filename)

    # コンテンツタイプのチェック
    allowed_types = [
        "audio/wav",
        "audio/wave",
        "audio/x-wav",
        "audio/mpeg",
        "audio/mp3",
        "audio/mp4",
        "audio/m4a",
    ]
    if file.content_type not in allowed_types:
        return VoiceFeaturesResponse(
            analysis_error_message=f"Unsupported file type: {file.content_type}"
        )

    try:
        # ファイル保存
        with open(temp_file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # 高速読み込み（16kHzで十分な精度、処理速度大幅向上）
        y, sr = librosa.load(temp_file_path, sr=16000)
        duration_seconds = len(y) / sr

        # 10秒制限の確認
        if duration_seconds > 10:
            return VoiceFeaturesResponse(
                analysis_error_message=(
                    "Audio file too long. Maximum 10 seconds allowed."
                )
            )

        # === 1. 音声区間検出（最も重要な前処理）===
        voice_segments = extract_voice_segments(y, sr)

        if not voice_segments:
            return VoiceFeaturesResponse(
                analysis_error_message="No speech detected in audio file"
            )

        # === 2. 高速ピッチ分析 ===
        avg_pitch = analyze_pitch_fast(y, sr)

        # === 3. 高速テンポ分析 ===
        tempo_result = analyze_tempo_fast(y, sr, voice_segments)
        avg_tempo, actual_speech_time, syllable_count = tempo_result

        # === 4. 高度な音量分析 ===
        volume_result = analyze_volume_advanced(y, sr, voice_segments)
        dbfs, lufs, dynamic_range = volume_result

        # === デバッグ情報 ===
        print("=== 音声分析結果 ===")
        print(f"総録音時間: {duration_seconds:.2f}秒")
        print(f"音声区間数: {len(voice_segments)}")
        print(f"実際の発話時間: {actual_speech_time:.2f}秒")
        print(
            f"ピッチ: {avg_pitch:.1f}Hz"
            if avg_pitch
            else "ピッチ: 検出できませんでした"
        )
        print(
            f"テンポ: {avg_tempo:.1f}音節/分"
            if avg_tempo
            else "テンポ: 検出できませんでした"
        )
        print(f"音量 (dBFS): {dbfs:.1f}dB" if dbfs else "音量: 検出できませんでした")
        print(f"音量 (LUFS): {lufs:.1f}LUFS" if lufs else "LUFS: 検出できませんでした")
        print(
            f"動的レンジ: {dynamic_range:.1f}dB"
            if dynamic_range
            else "動的レンジ: 検出できませんでした"
        )

        # === 品質チェック ===
        quality_notes = []

        if avg_pitch:
            if avg_pitch < 100:
                quality_notes.append("低めのピッチ")
            elif avg_pitch > 250:
                quality_notes.append("高めのピッチ")

        if dbfs:
            if dbfs < -30:
                quality_notes.append("音量が小さめ")
            elif dbfs > -10:
                quality_notes.append("音量が大きめ")

        if avg_tempo:
            if avg_tempo < 180:
                quality_notes.append("ゆっくりした話し方")
            elif avg_tempo > 350:
                quality_notes.append("速い話し方")

        if quality_notes:
            print("=== 音声特徴 ===")
            for note in quality_notes:
                print(f"- {note}")

        # レスポンスは従来のフォーマットを維持（互換性確保）
        return VoiceFeaturesResponse(
            pitch_value=float(avg_pitch) if avg_pitch else None,
            tempo_value=float(avg_tempo) if avg_tempo else None,
            volume_value=float(dbfs) if dbfs else None,  # dBFSを主要指標として使用
            duration_seconds=float(duration_seconds),
        )

    except Exception as analysis_exc:
        error_type = type(analysis_exc).__name__
        error_detail = str(analysis_exc)
        error_message = f"Audio analysis failed: {error_type}"
        if error_detail:
            error_message += f" - {error_detail}"

        print(f"Error during audio analysis: {error_type} - {error_detail}")
        return VoiceFeaturesResponse(analysis_error_message=error_message)

    finally:
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)
