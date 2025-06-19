class AddGenderToUsers < ActiveRecord::Migration[7.2]
  def change
    # integer型で性別を管理。例: 0:未設定, 1:男性, 2:女性
    # default: 0 としておくとユーザーが入力を忘れた時でも安全！
    add_column :users, :gender, :integer, default: 0, null: false
  end
end
