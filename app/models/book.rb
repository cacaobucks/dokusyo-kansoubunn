class Book < ApplicationRecord
  # === Associations ===
  belongs_to :user, counter_cache: true
  has_one_attached :image

  has_many :favorites, dependent: :destroy
  has_many :favorited_users, through: :favorites, source: :user
  has_many :book_comments, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :book_tags, dependent: :destroy
  has_many :tags, through: :book_tags

  # === Validations ===
  validates :title, presence: true, length: { maximum: 100 }
  validates :body, presence: true, length: { maximum: 2000 }

  # === Scopes ===
  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { order(favorites_count: :desc, created_at: :desc) }
  scope :highly_rated, -> { where("ratings_count >= ?", 3).order(average_rating: :desc) }
  scope :with_associations, -> { includes(:user, :tags).with_attached_image }

  # === Callbacks ===
  after_save :update_average_rating, if: -> { saved_change_to_ratings_count? }

  # === Instance Methods ===

  def image_url(size: :medium)
    sizes = { small: [100, 150], medium: [200, 300], large: [400, 600] }
    width, height = sizes[size]

    if image.attached?
      image.variant(resize_to_fill: [width, height])
    else
      "default-book.png"
    end
  end

  # 旧メソッド互換
  def get_image
    if image.attached?
      image
    else
      "default-book.png"
    end
  end

  def favorited_by?(user)
    return false unless user

    favorites.exists?(user_id: user.id)
  end

  def bookmarked_by?(user)
    return false unless user

    bookmarks.exists?(user_id: user.id)
  end

  def rating_by(user)
    return nil unless user

    ratings.find_by(user_id: user.id)
  end

  def tag_list=(names)
    return if names.blank?

    self.tags = names.split(",").map(&:strip).uniq.reject(&:blank?).map do |name|
      Tag.find_or_create_by(name: name.downcase)
    end
  end

  def tag_list
    tags.pluck(:name).join(", ")
  end

  private

  def update_average_rating
    avg = ratings.average(:score)&.round(1) || 0.0
    update_column(:average_rating, avg)
  end
end
