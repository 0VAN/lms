# frozen_string_literal: true

require_relative 'data_store'

module Library
  # Manages borrowing and returning flows.
  class Borrowing
    def initialize(store)
      @store = store
    end

    def borrow_book!(user, book_id)
      raise StandardError, 'forbidden' unless user && user[:role] == 'member'

      book = @store.find_book(book_id)
      raise StandardError, 'book not found' unless book

      if @store.active_borrowings_for_book(book_id).count >= book[:total_copies]
        raise StandardError, 'unavailable'
      end

      if @store.active_borrowings_for_user(user[:id]).any? { |b| b[:book_id] == book_id }
        raise StandardError, 'already borrowed'
      end

      @store.create_borrowing(user_id: user[:id], book_id: book_id, borrowed_at: Date.today, due_date: Date.today + 14)
    end

    def return_book!(user, borrowing_id)
      raise StandardError, 'forbidden' unless user && user[:role] == 'librarian'

      borrowing = @store.find_borrowing(borrowing_id)
      raise StandardError, 'borrowing not found' unless borrowing

      borrowing[:returned_at] = Date.today
      borrowing
    end

    def borrowings_for(user)
      return @store.all_borrowings if user[:role] == 'librarian'

      @store.borrowings_for_user(user[:id])
    end
  end
end
