from fastapi import FastAPI, File, UploadFile
from typing import Annotated
import shutil  # 一時ファイル操作用
import os  # 一時ファイル操作用
import librosa  # librosa をインポート
from schemas import VoiceFeaturesResponse

app = FastAPI()


@app.get("/ping")
async def ping():
    return {"ping": "pong"}


@app.get("/health")
async def health_check():
    return {"status": "ok"}


TEMP_AUDIO_DIR = "temp_audio_files"  # 一時ファイル保存ディレクトリ名


@app.on_event("startup")
async def startup_event():
    # アプリケーション起動時に一時ディレクトリを作成
    os.makedirs(TEMP_AUDIO_DIR, exist_ok=True)


@app.post("/analyze/voice_condition", response_model=VoiceFeaturesResponse)
async def analyze_voice_condition(file: Annotated[UploadFile, File()]):
    if not file:
        return VoiceFeaturesResponse(
            analysis_error_message="No file sent"
        )  # エラーメッセージを返す

    filename = file.filename or "uploaded_audio.wav"
    temp_file_path = os.path.join(TEMP_AUDIO_DIR, filename)

    # コンテンツタイプのチェック
    if file.content_type not in [
        "audio/wav",
        "audio/wave",
        "audio/x-wav",
        "audio/mpeg",
        "audio/mp3",
    ]:  # MP3も受け付ける例
        return VoiceFeaturesResponse(
            analysis_error_message=f"Unsupported file type: {file.content_type}. Please upload a WAV or MP3 file."
        )

    try:
        with open(temp_file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Librosaで音声分析
        y, sr = librosa.load(
            temp_file_path, sr=None
        )  # sr=Noneで元のサンプリングレートを維持
        duration_seconds = librosa.get_duration(y=y, sr=sr)

        # 声の高さ (平均ピッチ F0)
        pitches, magnitudes = librosa.piptrack(y=y, sr=sr)
        pitch_values = []
        for t_idx in range(pitches.shape[1]):  # tではなくt_idxに変更
            index = magnitudes[:, t_idx].argmax()
            pitch = pitches[index, t_idx]
            if pitch > 0:
                pitch_values.append(pitch)
        avg_pitch = (
            sum(pitch_values) / len(pitch_values) if pitch_values else None
        )  # Noneを許容

        # 話す速さ (テンポ BPM)
        onset_env = librosa.onset.onset_strength(y=y, sr=sr)
        tempo_values = librosa.beat.tempo(onset_envelope=onset_env, sr=sr)
        avg_tempo = float(tempo_values[0]) if tempo_values.size > 0 else None

        # 声の音量 (RMSエネルギーの平均 dB)
        rms = librosa.feature.rms(y=y)[0]  # rmsは2次元配列で返ってくることがあるので[0]
        avg_volume_db = (
            librosa.amplitude_to_db(rms, ref=1.0).mean() if rms.any() else None
        )  # ref=1.0で正規化

        # 分析成功時のレスポンス
        return VoiceFeaturesResponse(
            pitch_value=float(avg_pitch) if avg_pitch is not None else None,
            tempo_value=float(avg_tempo) if avg_tempo is not None else None,
            volume_value=float(avg_volume_db) if avg_volume_db is not None else None,
            duration_seconds=(
                float(duration_seconds) if duration_seconds is not None else None
            ),
        )
    except Exception as analysis_exc:  # 分析中のエラーを補足
        error_type = type(analysis_exc).__name__
        error_detail = str(analysis_exc)
        # ★ 型名と、もしあれば詳細メッセージを組み合わせる
        error_message = f"Audio analysis failed: Type={error_type}"
        if error_detail:
            error_message += f" - {error_detail}"

        print(f"Error during audio analysis: {error_type} - {error_detail}")
        # ★ 修正したエラーメッセージをレスポンスに含める
        return VoiceFeaturesResponse(analysis_error_message=error_message)
    finally:
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)  # ★一時ファイルを分析後に削除
