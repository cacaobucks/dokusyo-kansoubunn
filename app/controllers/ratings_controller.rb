class RatingsController < ApplicationController
  before_action :set_book

  def create
    @rating = current_user.ratings.find_or_initialize_by(book: @book)
    @rating.score = rating_params[:score]

    respond_to do |format|
      if @rating.save
        format.turbo_stream
        format.html { redirect_to @book }
      else
        format.html { redirect_to @book, alert: "評価できませんでした" }
      end
    end
  end

  def update
    @rating = current_user.ratings.find_by(book: @book)

    respond_to do |format|
      if @rating&.update(rating_params)
        format.turbo_stream { render :create }
        format.html { redirect_to @book }
      else
        format.html { redirect_to @book, alert: "評価を更新できませんでした" }
      end
    end
  end

  private

  def set_book
    @book = Book.find(params[:book_id])
  end

  def rating_params
    params.require(:rating).permit(:score)
  end
end
