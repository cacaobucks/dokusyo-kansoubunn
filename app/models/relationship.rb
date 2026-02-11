class Relationship < ApplicationRecord
  belongs_to :follower, class_name: "User", counter_cache: :following_count
  belongs_to :followed, class_name: "User", counter_cache: :followers_count

  validates :follower_id, presence: true
  validates :followed_id, presence: true
  validates :follower_id, uniqueness: { scope: :followed_id, message: "は既にフォローしています" }
  validate :not_self_follow

  after_create :create_notification

  private

  def not_self_follow
    errors.add(:followed_id, "自分自身はフォローできません") if follower_id == followed_id
  end

  def create_notification
    Notification.create!(
      recipient: followed,
      actor: follower,
      notifiable: self,
      action: "follow"
    )
  end
end
