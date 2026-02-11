class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :book, counter_cache: true

  validates :user_id, uniqueness: { scope: :book_id, message: "は既にいいねしています" }

  after_create :create_notification
  after_destroy :destroy_notification

  private

  def create_notification
    return if user == book.user

    Notification.create!(
      recipient: book.user,
      actor: user,
      notifiable: self,
      action: "favorite"
    )
  end

  def destroy_notification
    Notification.where(notifiable: self).destroy_all
  end
end
