class Rating < ApplicationRecord
  belongs_to :user
  belongs_to :book, counter_cache: true

  validates :score, presence: true, inclusion: { in: 1..5, message: "は1〜5の範囲で選択してください" }
  validates :user_id, uniqueness: { scope: :book_id, message: "は既に評価しています" }

  after_save :update_book_average
  after_destroy :update_book_average

  private

  def update_book_average
    avg = book.ratings.average(:score)&.round(1) || 0.0
    book.update_column(:average_rating, avg)
  end
end
