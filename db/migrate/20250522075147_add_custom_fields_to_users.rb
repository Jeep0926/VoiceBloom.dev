class AddCustomFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :terms_agreed_at, :datetime
    add_column :users, :practice_streak_days, :integer, default: 0
    add_column :users, :total_practice_days, :integer, default: 0
    add_column :users, :discarded_at, :datetime
    add_index :users, :discarded_at
    add_index :users, [:provider, :uid], unique: true
  end
end
