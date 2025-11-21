# frozen_string_literal: true

class BooksController < ApplicationController
  before_action -> { require_role!('librarian') }, only: %i[create update destroy]

  def index
    books = Library::Registry.book_service.search(
      title: params[:title],
      author: params[:author],
      genre: params[:genre]
    )
    render json: books
  end

  def create
    book = Library::Registry.book_service.add_book!(current_user, book_params.to_h.symbolize_keys)
    render json: book, status: :created
  end

  def update
    book = Library::Registry.book_service.update_book!(current_user, params[:id].to_i, book_params.to_h.symbolize_keys)
    render json: book
  end

  def destroy
    book = Library::Registry.book_service.delete_book!(current_user, params[:id].to_i)
    render json: book
  end

  private

  def book_params
    params.permit(:title, :author, :genre, :isbn, :total_copies)
  end
end
