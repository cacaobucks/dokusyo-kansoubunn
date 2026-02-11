class CreateTags < ActiveRecord::Migration[7.1]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.integer :books_count, default: 0, null: false

      t.timestamps
    end

    add_index :tags, :name, unique: true

    create_table :book_tags do |t|
      t.references :book, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
    end

    add_index :book_tags, [:book_id, :tag_id], unique: true
  end
end
