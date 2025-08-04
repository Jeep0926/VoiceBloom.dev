# frozen_string_literal: true

class PromptGeneratorService
  # 全てのプロンプトに共通で含める、品質を向上させるためのおまじない
  BASE_PROMPT = 'masterpiece, best quality, highres, original, upper body, simple background, clean background'

  # 生成画像の破綻を防ぐためのネガティブプロンプト
  NEGATIVE_PROMPT = <<~PROMPT.squish
    nsfw, lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit,
    fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts,
    signature, watermark, username, blurry, artist name
  PROMPT

  # 表情とプロンプトのマッピング
  EXPRESSION_MAP = {
    neutral: ['gentle smile', 'front view', 'calm expression'],
    positive: ['big smile', 'joyful', 'sparkling eyes'],
    energetic: ['laughing', 'open mouth', 'energetic pose', 'looking up'],
    calm: ['smiling with eyes closed', 'calm atmosphere'],
    tired: ['worried face', 'looking down', 'sighing']
  }.freeze

  def initialize(user, expression: :neutral)
    @user = user
    @expression = expression
  end

  # --- メインの実行メソッド ---
  def call
    # 各要素のプロンプトを配列として組み立て、カンマ区切りの一つの文字列に変換
    positive_prompt = [
      BASE_PROMPT,
      gender_prompt,
      character_feature_prompts,
      expression_prompts
    ].flatten.compact.join(', ')

    # ポジティブ・ネガティブ両方のプロンプトをハッシュで返す
    {
      positive: positive_prompt,
      negative: NEGATIVE_PROMPT
    }
  end

  private

  # 性別に基づくプロンプトを返す
  def gender_prompt
    @user.male? ? '1boy, solo' : '1girl, solo'
  end

  # 声の基準値からキャラクターの身体的・内面的特徴を生成する
  def character_feature_prompts
    [
      *pitch_prompts,
      *tempo_prompts,
      *volume_prompts,
      eye_color_prompt
    ]
  end

  # 指定された表情に応じたプロンプトを返す
  def expression_prompts
    EXPRESSION_MAP.fetch(@expression, [])
  end

  # 声の高さ (Pitch) -> 髪型や年齢
  def pitch_prompts
    return unless @user.baseline_pitch

    if @user.baseline_pitch > 200 # 女性の平均より高めの場合
      ['short hair', 'energetic', 'bright eyes']
    elsif @user.baseline_pitch < 140 # 男性の平均より低めの場合
      ['long hair', 'mature', 'elegant']
    else
      ['medium hair']
    end
  end

  # 話す速さ (Tempo) -> 雰囲気や体型
  def tempo_prompts
    return unless @user.baseline_tempo

    if @user.baseline_tempo > 350
      %w[cheerful fit]
    elsif @user.baseline_tempo < 250
      ['calm', 'slender', 'reading a book']
    end
  end

  # 声の音量 (Volume) -> 性格
  def volume_prompts
    return unless @user.baseline_volume

    if @user.baseline_volume > -15
      %w[confident extrovert]
    elsif @user.baseline_volume < -25
      %w[shy introvert blushing]
    end
  end

  # ユーザーIDに応じて目の色を固定し、キャラクターの個性を出す
  def eye_color_prompt
    eye_colors = ['blue eyes', 'green eyes', 'brown eyes', 'purple eyes']
    eye_colors[@user.id % eye_colors.length]
  end
end
