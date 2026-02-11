class AddCountersToBooks < ActiveRecord::Migration[7.1]
  def change
    change_table :books, bulk: true do |t|
      t.integer :favorites_count, default: 0, null: false
      t.integer :book_comments_count, default: 0, null: false
      t.integer :ratings_count, default: 0, null: false
      t.decimal :average_rating, precision: 2, scale: 1, default: 0.0
    end

    add_index :books, :average_rating
    add_index :books, :created_at
  end
end
