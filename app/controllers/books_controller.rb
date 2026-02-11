class BooksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_book, only: [:show, :edit, :update, :destroy]
  before_action :authorize_book, only: [:edit, :update, :destroy]

  def index
    @books = Book.with_associations
                 .recent
                 .page(params[:page])
                 .per(12)
    @book = Book.new
  end

  def show
    @book_comment = BookComment.new
    @book_comments = @book.book_comments
                          .includes(:user)
                          .order(created_at: :desc)
    @user_rating = @book.rating_by(current_user)
  end

  def new
    @book = Book.new
  end

  def create
    @book = current_user.books.build(book_params)

    if @book.save
      redirect_to @book, notice: "投稿しました"
    else
      @books = Book.with_associations.recent.page(params[:page]).per(12)
      render :index, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @book.update(book_params)
      redirect_to @book, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @book.destroy
    redirect_to books_path, notice: "削除しました", status: :see_other
  end

  private

  def set_book
    @book = Book.find(params[:id])
  end

  def authorize_book
    unless @book.user == current_user
      redirect_to books_path, alert: "この操作を行う権限がありません"
    end
  end

  def book_params
    params.require(:book).permit(:title, :body, :image, :tag_list)
  end
end
