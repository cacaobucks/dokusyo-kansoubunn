class HomeController < ApplicationController
  def top
    if user_signed_in?
      redirect_to books_path
    else
      @trending_books = Book.with_associations.popular.limit(6)
      @stats = {
        books_count: Book.count,
        users_count: User.count,
        comments_count: BookComment.count
      }
    end
  end

  def about
  end
end
