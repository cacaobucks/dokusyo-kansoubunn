class FavoritesController < ApplicationController
  before_action :set_book

  def create
    @favorite = current_user.favorites.build(book: @book)

    respond_to do |format|
      if @favorite.save
        format.turbo_stream
        format.html { redirect_back(fallback_location: @book) }
      else
        format.html { redirect_back(fallback_location: @book, alert: "いいねできませんでした") }
      end
    end
  end

  def destroy
    @favorite = current_user.favorites.find_by(book: @book)
    @favorite&.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: @book) }
    end
  end

  private

  def set_book
    @book = Book.find(params[:book_id])
  end
end
