# frozen_string_literal: true

require_relative 'data_store'

module Library
  # Builds dashboard responses for librarians and members.
  class Dashboard
    def initialize(store)
      @store = store
    end

    def for_user(user)
      user[:role] == 'librarian' ? librarian_view : member_view(user)
    end

    private

    def librarian_view
      overdue = @store.all_borrowings.select { |b| b[:due_date] <= Date.today && b[:returned_at].nil? }
      {
        total_books: @store.all_books.count,
        total_borrowed: @store.all_borrowings.count { |b| b[:returned_at].nil? },
        due_today: @store.all_borrowings.count { |b| b[:due_date] == Date.today && b[:returned_at].nil? },
        overdue_members: overdue.map { |b| member_summary(b[:user_id]) }.compact.uniq
      }
    end

    def member_view(user)
      borrowings = @store.borrowings_for_user(user[:id]).reject { |b| b[:returned_at] }
      {
        borrowed: borrowings.map do |borrow|
          book = @store.find_book(borrow[:book_id])
          {
            book: book&.dig(:title),
            due_date: borrow[:due_date],
            overdue: borrow[:due_date] < Date.today
          }
        end
      }
    end

    def member_summary(user_id)
      member = @store.find_user(user_id)
      return unless member

      { id: member[:id], email: member[:email] }
    end
  end
end
