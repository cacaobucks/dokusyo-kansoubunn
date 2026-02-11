class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User"
  belongs_to :notifiable, polymorphic: true

  ACTIONS = %w[favorite comment follow].freeze

  validates :action, presence: true, inclusion: { in: ACTIONS }

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def read?
    read_at.present?
  end

  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end

  def message
    case action
    when "favorite"
      "#{actor.name}さんがあなたの投稿にいいねしました"
    when "comment"
      "#{actor.name}さんがあなたの投稿にコメントしました"
    when "follow"
      "#{actor.name}さんがあなたをフォローしました"
    else
      "新しい通知があります"
    end
  end

  def target_path
    case action
    when "favorite", "comment"
      notifiable&.book
    when "follow"
      actor
    end
  end
end
