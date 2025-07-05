class CreateCharacterImages < ActiveRecord::Migration[7.2]
  def change
    create_table :character_images do |t|
      t.references :user, null: false, foreign_key: true
      t.string :expression, null: false # 表情の種類 (例: 'neutral', 'happy')

      t.timestamps
    end
    # user_id と expression の組み合わせはユニーク
    add_index :character_images, [:user_id, :expression], unique: true
  end
end
