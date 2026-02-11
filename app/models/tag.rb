class Tag < ApplicationRecord
  has_many :book_tags, dependent: :destroy
  has_many :books, through: :book_tags

  validates :name, presence: true, uniqueness: true, length: { maximum: 30 }

  scope :popular, -> { order(books_count: :desc).limit(20) }

  before_validation :normalize_name

  private

  def normalize_name
    self.name = name&.downcase&.strip
  end
end
