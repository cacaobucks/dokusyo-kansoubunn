class User < ApplicationRecord
  # === Devise ===
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # === Attachments ===
  has_one_attached :profile_image

  # === Associations ===
  has_many :books, dependent: :destroy
  has_many :book_comments, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorited_books, through: :favorites, source: :book
  has_many :ratings, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarked_books, through: :bookmarks, source: :book

  # フォロー関係
  has_many :active_relationships, class_name: "Relationship",
                                  foreign_key: "follower_id",
                                  dependent: :destroy
  has_many :passive_relationships, class_name: "Relationship",
                                   foreign_key: "followed_id",
                                   dependent: :destroy
  has_many :following, through: :active_relationships, source: :followed
  has_many :followers, through: :passive_relationships, source: :follower

  # 通知
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy
  has_many :sent_notifications, class_name: "Notification",
                                foreign_key: :actor_id,
                                dependent: :destroy

  # === Validations ===
  validates :name, presence: true, length: { minimum: 2, maximum: 20 }, uniqueness: true
  validates :username, uniqueness: true, allow_nil: true,
                       format: { with: /\A[a-zA-Z0-9_]+\z/, message: "は英数字とアンダースコアのみ使用できます" },
                       length: { minimum: 3, maximum: 20 }
  validates :introduction, length: { maximum: 160 }

  # === Scopes ===
  scope :recent, -> { order(created_at: :desc) }

  # === Callbacks ===
  before_validation :set_default_username, on: :create

  # === Instance Methods ===

  def avatar_url(size: :medium)
    sizes = { small: [40, 40], medium: [100, 100], large: [200, 200] }
    width, height = sizes[size]

    if profile_image.attached?
      profile_image.variant(resize_to_fill: [width, height])
    else
      "default-avatar.png"
    end
  end

  # 旧メソッド互換
  def get_profile_image(width, height)
    if profile_image.attached?
      profile_image.variant(resize_to_limit: [width, height]).processed
    else
      "default-avatar.png"
    end
  end

  # フォロー操作
  def follow(other_user)
    return if self == other_user || following?(other_user)

    following << other_user
  end

  def unfollow(other_user)
    following.delete(other_user)
  end

  def following?(other_user)
    following.include?(other_user)
  end

  # タイムライン取得
  def feed
    following_ids_subquery = active_relationships.select(:followed_id)
    Book.where(user_id: following_ids_subquery)
        .or(Book.where(user_id: id))
        .includes(:user, :tags)
        .with_attached_image
        .order(created_at: :desc)
  end

  # 未読通知数
  def unread_notifications_count
    notifications.unread.count
  end

  private

  def set_default_username
    return if username.present?

    base = name&.parameterize(separator: "_") || "user"
    self.username = self.class.generate_username(base)
  end

  def self.generate_username(base)
    username = base.downcase.gsub(/[^a-z0-9_]/, "_")[0, 15]
    return username unless exists?(username: username)

    loop do
      candidate = "#{username}_#{SecureRandom.hex(3)}"
      return candidate unless exists?(username: candidate)
    end
  end
end
