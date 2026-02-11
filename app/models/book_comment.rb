class BookComment < ApplicationRecord
  belongs_to :user
  belongs_to :book, counter_cache: true

  validates :comment, presence: true, length: { maximum: 500 }

  after_create :create_notification

  private

  def create_notification
    return if user == book.user

    Notification.create!(
      recipient: book.user,
      actor: user,
      notifiable: self,
      action: "comment"
    )
  end
end
