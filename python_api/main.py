from fastapi import FastAPI, File, UploadFile
from typing import Annotated
import shutil  # 一時ファイル操作用
import os  # 一時ファイル操作用
import librosa  # librosa をインポート
import numpy as np  # numpy追加
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


def analyze_speech_tempo_improved(y, sr):
    """
    正確な話速（テンポ）分析
    無音部分を除外し、実際の発話時間で計算
    """
    try:
        # 1. 音声区間の検出（無音部分を除外）
        # top_db=20: 20dB以下を無音とする（環境に応じて調整可能）
        intervals = librosa.effects.split(y, top_db=20)
        
        if len(intervals) == 0:
            return None, 0, 0
        
        # 2. 実際の発話時間を計算
        speech_duration = 0
        speech_segments = []
        
        for interval in intervals:
            start, end = interval
            speech_duration += (end - start) / sr
            speech_segments.append(y[start:end])
        
        # 3. 発話部分を結合
        if len(speech_segments) > 0:
            speech_audio = np.concatenate(speech_segments)
            
            # 4. 発話部分のみでonset検出（音節検出）
            onset_frames = librosa.onset.onset_detect(
                y=speech_audio, 
                sr=sr, 
                units='time',
                hop_length=512,
                backtrack=True,  # より正確な開始点検出
                delta=0.1,       # 感度調整（小さいほど敏感）
                wait=0.03        # 最小間隔（30ms）
            )
            
            syllable_count = len(onset_frames)
            
            # 5. 実際の発話時間で話速を計算
            if speech_duration > 0:
                syllables_per_minute = (syllable_count / speech_duration) * 60
                return syllables_per_minute, speech_duration, syllable_count
        
        return None, 0, 0
        
    except Exception as e:
        print(f"Tempo analysis error: {e}")
        return None, 0, 0


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

        # Librosaで音声分析 - 22050Hzに統一して処理速度向上と精度安定化
        y, sr = librosa.load(temp_file_path, sr=22050)
        duration_seconds = librosa.get_duration(y=y, sr=sr)

        # === 1. 声の高さ (基本周波数 F0) - YINメソッドで正確に分析 ===
        f0 = librosa.yin(y, fmin=50, fmax=400)  # 人間の声の範囲で制限
        # 無音部分（f0=50未満）を除外し、有効な値のみ取得
        valid_f0 = f0[(f0 >= 50) & (f0 <= 400)]
        avg_pitch = float(np.median(valid_f0)) if len(valid_f0) > 0 else None

        # === 2. 話す速さ - 改善されたテンポ分析 ===
        syllables_per_minute, actual_speech_time, syllable_count = analyze_speech_tempo_improved(y, sr)
        
        # デバッグ情報をログ出力（本番では削除可能）
        if syllables_per_minute is not None:
            print(f"=== テンポ分析結果 ===")
            print(f"総録音時間: {duration_seconds:.2f}秒")
            print(f"実際の発話時間: {actual_speech_time:.2f}秒")
            print(f"検出された音節数: {syllable_count}")
            print(f"話速: {syllables_per_minute:.1f}音節/分")
            print(f"無音時間: {duration_seconds - actual_speech_time:.2f}秒")
        
        avg_tempo = float(syllables_per_minute) if syllables_per_minute is not None else None

        # === 3. 声の音量 (dBFS基準での正確な測定) ===
        # 音声の実効値（RMS）を計算
        rms_energy = np.sqrt(np.mean(y**2))
        
        # dBFS（Full Scale decibels）として計算 - 0dBFSが最大値
        if rms_energy > 0:
            avg_volume_db = float(20 * np.log10(rms_energy))
        else:
            avg_volume_db = None

        # === 追加情報: 音声品質の簡易判定 ===
        quality_notes = []
        
        # ピッチの妥当性チェック
        if avg_pitch is not None:
            if avg_pitch < 80:
                quality_notes.append("ピッチが低め（男性の低い声またはノイズの可能性）")
            elif avg_pitch > 300:
                quality_notes.append("ピッチが高め（女性の高い声または倍音検出の可能性）")
        
        # 音量の妥当性チェック
        if avg_volume_db is not None:
            if avg_volume_db < -40:
                quality_notes.append("音量が小さすぎます（録音レベルを上げることを推奨）")
            elif avg_volume_db > -5:
                quality_notes.append("音量が大きすぎます（音割れの可能性）")
        
        # テンポの妥当性チェック
        if avg_tempo is not None:
            if avg_tempo < 200:
                quality_notes.append("話速が遅め（ゆっくりとした話し方）")
            elif avg_tempo > 500:
                quality_notes.append("話速が速め（早口な話し方）")
        
        # デバッグ用: 品質チェック結果をログ出力
        if quality_notes:
            print("=== 音声品質チェック ===")
            for note in quality_notes:
                print(f"- {note}")

        # 分析成功時のレスポンス
        return VoiceFeaturesResponse(
            pitch_value=avg_pitch,
            tempo_value=avg_tempo,
            volume_value=avg_volume_db,
            duration_seconds=float(duration_seconds) if duration_seconds is not None else None,
        )
        
    except Exception as analysis_exc:  # 分析中のエラーを補足
        error_type = type(analysis_exc).__name__
        error_detail = str(analysis_exc)
        # 型名と、もしあれば詳細メッセージを組み合わせる
        error_message = f"Audio analysis failed: Type={error_type}"
        if error_detail:
            error_message += f" - {error_detail}"

        print(f"Error during audio analysis: {error_type} - {error_detail}")
        # 修正したエラーメッセージをレスポンスに含める
        return VoiceFeaturesResponse(analysis_error_message=error_message)
    finally:
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)  # 一時ファイルを分析後に削除