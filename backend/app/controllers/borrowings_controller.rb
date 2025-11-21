# frozen_string_literal: true

class BorrowingsController < ApplicationController
  before_action -> { require_role!('member') }, only: :create
  before_action -> { require_role!('librarian') }, only: :return_book
  before_action -> { require_user! }, only: :index

  def create
    borrowing = Library::Registry.borrowing_service.borrow_book!(current_user, params[:id].to_i)
    render json: borrowing, status: :created
  end

  def return_book
    borrowing = Library::Registry.borrowing_service.return_book!(current_user, params[:id].to_i)
    render json: borrowing
  end

  def index
    borrowings = Library::Registry.borrowing_service.borrowings_for(current_user)
    render json: borrowings
  end
end
