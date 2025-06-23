# frozen_string_literal: true

class User < ApplicationRecord
  include Discard::Model
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, presence: true, length: { maximum: 30 }

  has_one_attached :profile_image
  has_many :voice_condition_logs, dependent: :destroy
  has_many :practice_session_logs, dependent: :destroy
  has_many :practice_attempt_logs, dependent: :destroy # 直接持つ場合、またはセッション経由で持つ場合は不要

  # 論理削除したユーザーを検索対象に含めないため
  default_scope { kept }

  # enum を使って gender の値をシンボルで扱えるようにする
  enum :gender, { unset: 0, male: 1, female: 2, other: 3 }

  # gender に保存される値が、enum で定義したキー ("unset", "male", "female", "other") のいずれかであることを保証。
  # 意図しない値がデータベースに保存されるのを防ぐ。
  validates :gender, inclusion: { in: genders.keys }

  # 練習セッション完了時にカウンターを更新するメソッド
  def update_practice_stats!(completed_session)
    # 更新対象の属性をハッシュで準備し、一度のDBアクセスで更新する
    attributes_to_update = {
      total_practice_sessions_count: total_practice_sessions_count + 1
    }

    # このセッションが完了した日付 (ユーザーのタイムゾーン) を取得
    date_of_completion = completed_session.session_ended_at.in_time_zone(Time.zone).to_date

    # 同じ日に完了した他のセッションが存在しない場合にのみ、総学習日数を増やす
    unless practice_day_already_counted?(completed_session, date_of_completion)
      attributes_to_update[:total_practice_days] = total_practice_days + 1
    end

    # バリデーションを実行しつつ、カウンターをアトミックに更新
    # (元のメソッド名に `!` が付いているため `update!` を使用)
    update!(attributes_to_update)
  end

  private

  # 指定された日に練習日数がすでにカウント済みかを確認する
  def practice_day_already_counted?(completed_session, date_of_completion)
    # `AT TIME ZONE` を使った複雑な変換をやめ、日付の範囲で比較する
    # to_date で取得した日付はそのタイムゾーンの0時なので、
    # beginning_of_day と end_of_day でその日の開始から終了までの範囲を作成する
    start_of_day = date_of_completion.beginning_of_day
    end_of_day = date_of_completion.end_of_day

    practice_session_logs
      .where.not(id: completed_session.id) # 今回のセッションは除く
      .where.not(session_ended_at: nil)    # 未完了のセッションは除く
      .where(session_ended_at: start_of_day..end_of_day) # その日の範囲内に完了記録があるか
      .exists?
  end
end
