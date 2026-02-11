class SearchController < ApplicationController
  def index
    @query = params[:q]
    @type = params[:type] || "books"

    return if @query.blank?

    case @type
    when "users"
      @users = User.where("name LIKE ? OR username LIKE ?", "%#{@query}%", "%#{@query}%")
                   .page(params[:page])
                   .per(20)
    else
      @books = Book.where("title LIKE ? OR body LIKE ?", "%#{@query}%", "%#{@query}%")
                   .with_associations
                   .recent
                   .page(params[:page])
                   .per(12)
    end
  end
end
