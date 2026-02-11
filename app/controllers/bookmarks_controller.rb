class BookmarksController < ApplicationController
  before_action :set_book, only: [:create, :destroy]

  def index
    @books = current_user.bookmarked_books
                         .with_associations
                         .page(params[:page])
                         .per(12)
  end

  def create
    @bookmark = current_user.bookmarks.build(book: @book)

    respond_to do |format|
      if @bookmark.save
        format.turbo_stream
        format.html { redirect_back(fallback_location: @book) }
      else
        format.html { redirect_back(fallback_location: @book, alert: "ブックマークできませんでした") }
      end
    end
  end

  def destroy
    @bookmark = current_user.bookmarks.find_by(book: @book)
    @bookmark&.destroy

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
