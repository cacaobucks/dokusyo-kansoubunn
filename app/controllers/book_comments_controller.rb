class BookCommentsController < ApplicationController
  before_action :set_book

  def create
    @book_comment = current_user.book_comments.build(book_comment_params)
    @book_comment.book = @book

    respond_to do |format|
      if @book_comment.save
        format.turbo_stream
        format.html { redirect_to @book }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "comment_form",
            partial: "book_comments/form",
            locals: { book: @book, book_comment: @book_comment }
          )
        end
        format.html { redirect_to @book, alert: "コメントを投稿できませんでした" }
      end
    end
  end

  def destroy
    @book_comment = @book.book_comments.find(params[:id])

    if @book_comment.user == current_user
      @book_comment.destroy

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @book }
      end
    else
      redirect_to @book, alert: "この操作を行う権限がありません"
    end
  end

  private

  def set_book
    @book = Book.find(params[:book_id])
  end

  def book_comment_params
    params.require(:book_comment).permit(:comment)
  end
end
