class NotificationsController < ApplicationController
  def index
    @notifications = current_user.notifications
                                 .includes(:actor, :notifiable)
                                 .recent
                                 .page(params[:page])
                                 .per(20)
  end

  def mark_as_read
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: notifications_path) }
    end
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "notifications_list",
          partial: "notifications/list",
          locals: { notifications: current_user.notifications.recent.limit(20) }
        )
      end
      format.html { redirect_to notifications_path, notice: "すべて既読にしました" }
    end
  end
end
