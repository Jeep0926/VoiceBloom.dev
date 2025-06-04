class CreatePracticeExercises < ActiveRecord::Migration[7.2]
  def change
    create_table :practice_exercises do |t|
      t.string :title, null: false
      t.text :text_content, null: false
      t.string :category
      t.integer :difficulty_level
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end

    add_index :practice_exercises, :title
    # 複合インデックスは順番が重要！
    # ユーザーがお題を探す際、「有効なものの中から、特定のカテゴリのお題を探す」という流れが自然。
    # 👉is_active でまず絞り込み、次に category で絞り込む
    add_index :practice_exercises, [:is_active, :category]
  end
end
