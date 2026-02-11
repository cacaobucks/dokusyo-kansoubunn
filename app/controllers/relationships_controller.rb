class RelationshipsController < ApplicationController
  before_action :set_user

  def create
    current_user.follow(@user)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: @user) }
    end
  end

  def destroy
    current_user.unfollow(@user)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: @user) }
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
