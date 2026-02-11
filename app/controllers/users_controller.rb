class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :followers, :following]
  before_action :authorize_user, only: [:edit, :update]

  def index
    @users = User.recent.page(params[:page]).per(20)
  end

  def show
    @books = @user.books
                  .with_associations
                  .recent
                  .page(params[:page])
                  .per(12)
    @book = Book.new
  end

  def edit; end

  def update
    respond_to do |format|
      if @user.update(user_params)
        format.turbo_stream { flash.now[:notice] = "プロフィールを更新しました" }
        format.html { redirect_to @user, notice: "プロフィールを更新しました" }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "user_form",
            partial: "users/form",
            locals: { user: @user }
          )
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def followers
    @users = @user.followers.page(params[:page]).per(20)
    render :follow_list
  end

  def following
    @users = @user.following.page(params[:page]).per(20)
    render :follow_list
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def authorize_user
    unless @user == current_user
      redirect_to user_path(current_user), alert: "この操作を行う権限がありません"
    end
  end

  def user_params
    params.require(:user).permit(:name, :username, :introduction, :profile_image)
  end
end
