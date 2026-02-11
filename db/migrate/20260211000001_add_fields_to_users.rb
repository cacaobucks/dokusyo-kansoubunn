class AddFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :username
      t.integer :followers_count, default: 0, null: false
      t.integer :following_count, default: 0, null: false
      t.integer :books_count, default: 0, null: false
    end

    add_index :users, :username, unique: true
  end
end
