# frozen_string_literal: true

require 'securerandom'
require 'date'
require_relative 'seed_data'

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
    def seed_sample_data!(preset: :demo)
      return if @seeded

      data = Library::SeedData.fetch(preset)

      users_by_email = {}
      data[:users].each do |user|
        created = create_user(email: user[:email], password: user[:password], role: user[:role])
        users_by_email[user[:email]] = created
      end

      books_by_isbn = {}
      data[:books].each do |book|
        created = create_book(
          title: book[:title],
          author: book[:author],
          genre: book[:genre],
          isbn: book[:isbn],
          total_copies: book[:total_copies]
        )
        books_by_isbn[book[:isbn]] = created
      end

      data[:borrowings].each do |borrowing|
        user = users_by_email[borrowing[:user_email]]
        book = books_by_isbn[borrowing[:book_isbn]]
        next unless user && book

        borrowed_at = borrowing[:borrowed_at] || (Date.today + (borrowing[:borrowed_at_offset_days] || 0))
        due_date = borrowing[:due_date] || borrowed_at + (borrowing[:loan_length_days] || 14)
        record = create_borrowing(user_id: user[:id], book_id: book[:id], borrowed_at: borrowed_at, due_date: due_date)

        record[:returned_at] = borrowing[:returned_at] if borrowing[:returned_at]
        record[:returned_at] = borrowed_at + borrowing[:returned_after_days] if borrowing[:returned_after_days]
      end

      @seeded = true
    end
  end
end
