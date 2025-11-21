# frozen_string_literal: true

require 'securerandom'
require 'date'

module Library
  # In-memory persistence for users, books, borrowings, and tokens.
  class DataStore
    attr_reader :users, :books, :borrowings, :tokens

    def initialize
      @users = []
      @books = []
      @borrowings = []
      @tokens = {}
      @user_seq = 0
      @book_seq = 0
      @borrow_seq = 0
      @seeded = false
    end

    def create_user(email:, password:, role: 'member')
      @user_seq += 1
      user = { id: @user_seq, email: email, password: password, role: role }
      @users << user
      user
    end

    def find_user_by_email(email)
      @users.find { |u| u[:email] == email }
    end

    def find_user(id)
      @users.find { |u| u[:id] == id }
    end

    def store_token(user_id)
      token = SecureRandom.hex(16)
      @tokens[token] = user_id
      token
    end

    def token_owner(token)
      @tokens[token]
    end

    def delete_token(token)
      @tokens.delete(token)
    end

    def create_book(attrs)
      @book_seq += 1
      book = {
        id: @book_seq,
        title: attrs[:title],
        author: attrs[:author],
        genre: attrs[:genre],
        isbn: attrs[:isbn],
        total_copies: attrs[:total_copies].to_i
      }
      @books << book
      book
    end

    def find_book(id)
      @books.find { |b| b[:id] == id }
    end

    def update_book(id, attrs)
      book = find_book(id)
      return unless book

      attrs.each { |k, v| book[k] = v if v }
      book
    end

    def delete_book(id)
      book = find_book(id)
      return unless book

      @books.delete(book)
      @borrowings.delete_if { |b| b[:book_id] == id }
      book
    end

    def all_books
      @books.dup
    end

    def create_borrowing(user_id:, book_id:, borrowed_at:, due_date:)
      @borrow_seq += 1
      borrow = {
        id: @borrow_seq,
        user_id: user_id,
        book_id: book_id,
        borrowed_at: borrowed_at,
        due_date: due_date,
        returned_at: nil
      }
      @borrowings << borrow
      borrow
    end

    def find_borrowing(id)
      @borrowings.find { |b| b[:id] == id }
    end

    def borrowings_for_user(user_id)
      @borrowings.select { |b| b[:user_id] == user_id }
    end

    def active_borrowings_for_user(user_id)
      borrowings_for_user(user_id).reject { |b| b[:returned_at] }
    end

    def active_borrowings_for_book(book_id)
      @borrowings.select { |b| b[:book_id] == book_id && b[:returned_at].nil? }
    end

    def all_borrowings
      @borrowings.dup
    end

    # Optional utility to pre-populate sample data for manual testing.
    def seed_sample_data!
      return if @seeded

      librarian = create_user(email: 'librarian@example.com', password: 'password', role: 'librarian')
      member = create_user(email: 'member@example.com', password: 'password', role: 'member')

      books = [
        create_book(title: 'The Ruby Way', author: 'Hal Fulton', genre: 'Programming', isbn: '9780321714633', total_copies: 3),
        create_book(title: 'Practical Object-Oriented Design', author: 'Sandi Metz', genre: 'Programming', isbn: '9780321721334', total_copies: 2),
        create_book(title: 'The Pragmatic Programmer', author: 'Andrew Hunt', genre: 'Programming', isbn: '9780135957059', total_copies: 1)
      ]

      today = Date.today
      create_borrowing(user_id: member[:id], book_id: books.first[:id], borrowed_at: today - 1, due_date: today + 13)
      create_borrowing(user_id: member[:id], book_id: books.last[:id], borrowed_at: today - 20, due_date: today - 6)

      @seeded = true
    end
  end
end
