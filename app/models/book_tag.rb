class BookTag < ApplicationRecord
  belongs_to :book
  belongs_to :tag, counter_cache: :books_count

  validates :book_id, uniqueness: { scope: :tag_id }
end
