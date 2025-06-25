# frozen_string_literal: true

# 本番環境で、最初の練習問題が既に存在する場合は、このスクリプトの実行をここで終了する
# これにより、db:seed コマンドが何度実行されてもデータが重複して作成されるのを防ぐ
if Rails.env.production? && PracticeExercise.exists?(title: '朝のあいさつ')
  Rails.logger.info 'Practice exercises have already been seeded. Skipping.'
  return
end

# Returns the full path to the audio file for the given filename
def audio_file_path(audio_filename)
  Rails.root.join('db', 'seeds', 'audio_samples', audio_filename)
end

# Logs a warning if the audio file does not exist; returns true if missing
def log_and_check_file_missing(path, exercise_title, audio_filename)
  unless File.exist?(path)
    Rails.logger.warn(
      "WARNING: Audio file '#{audio_filename}' not found at " \
      "'#{path}' for exercise '#{exercise_title}'."
    )
    return true
  end

  false
end

# Logs info if the audio is already attached; returns true if already attached
def log_and_check_already_attached(exercise, audio_filename)
  if exercise.sample_audio.attached? && exercise.sample_audio.filename.to_s == audio_filename
    Rails.logger.info(
      "Audio '#{audio_filename}' already attached to '#{exercise.title}'."
    )
    return true
  end

  false
end

# Handles attaching the audio file to the record
def attach_audio_file(exercise, path, audio_filename)
  exercise.sample_audio.attach(
    io: File.open(path),
    filename: audio_filename,
    content_type: 'audio/wav'
  )
end

# Logs the result of the attachment, handling exceptions
def log_audio_attachment_result(exercise, path, audio_filename)
  attach_audio_file(exercise, path, audio_filename)
  Rails.logger.info(
    "Audio '#{audio_filename}' attached to '#{exercise.title}'."
  )
rescue StandardError => e
  Rails.logger.error(
    "ERROR attaching audio '#{audio_filename}' to '#{exercise.title}': #{e.message}"
  )
end

# Wrapper method that coordinates attachment logic
def attach_audio_to_exercise(exercise, audio_filename)
  path = audio_file_path(audio_filename)
  return if log_and_check_file_missing(path, exercise.title, audio_filename)
  return if log_and_check_already_attached(exercise, audio_filename)

  log_audio_attachment_result(exercise, path, audio_filename)
end

Rails.logger.info('Seeding PracticeExercises...')

practice_exercises_data = [
  {
    title: '朝のあいさつ',
    text_content: 'おはようございます',
    category: '日常会話',
    difficulty_level: 1,
    is_active: true,
    duration_minutes: 1,
    sample_audio_filename: '01_ohayougozaimasu.wav'
  },
  {
    title: '昼のあいさつ',
    text_content: 'こんにちは',
    category: '日常会話',
    difficulty_level: 1,
    is_active: true,
    duration_minutes: 1,
    sample_audio_filename: '02_konnichiwa.wav'
  },
  {
    title: '感謝を伝える',
    text_content: 'ありがとうございます',
    category: '日常会話',
    difficulty_level: 1,
    is_active: true,
    duration_minutes: 1,
    sample_audio_filename: '03_arigatougozaimasu.wav'
  },
  {
    title: 'お願いする時',
    text_content: 'よろしくお願いします',
    category: '日常会話',
    difficulty_level: 1,
    is_active: true,
    duration_minutes: 1,
    sample_audio_filename: '04_yoroshikuonegaishimasu.wav'
  },
  {
    title: '労いの言葉',
    text_content: 'お疲れさま',
    category: '日常会話',
    difficulty_level: 1,
    is_active: true,
    duration_minutes: 1,
    sample_audio_filename: '05_otsukaresama.wav'
  }
]

practice_exercises_data.each do |exercise_data|
  audio_filename = exercise_data.delete(:sample_audio_filename)
  exercise = PracticeExercise.find_or_initialize_by(title: exercise_data[:title])
  exercise.assign_attributes(exercise_data)

  attach_audio_to_exercise(exercise, audio_filename) if audio_filename.present?

  if exercise.save
    Rails.logger.info(
      "Successfully seeded or updated: '#{exercise.title}' (ID: #{exercise.id})"
    )
  else
    Rails.logger.error(
      "ERROR seeding '#{exercise.title}': #{exercise.errors.full_messages.join(', ')}"
    )
  end

  Rails.logger.info('-' * 20)
end

Rails.logger.info('Finished seeding PracticeExercises.')
