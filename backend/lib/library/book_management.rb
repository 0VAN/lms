# frozen_string_literal: true

require_relative 'data_store'

module Library
  # Manages CRUD operations on books.
  class BookManagement
    def initialize(store)
      @store = store
    end

    def add_book!(user, attrs)
      ensure_librarian!(user)
      validate_book!(attrs)
      @store.create_book(attrs)
    end

    def update_book!(user, id, attrs)
      ensure_librarian!(user)
      book = @store.update_book(id, attrs)
      raise StandardError, 'book not found' unless book

      book
    end

    def delete_book!(user, id)
      ensure_librarian!(user)
      book = @store.delete_book(id)
      raise StandardError, 'book not found' unless book

      book
    end

    def search(query = {})
      books = @store.all_books
      query.each do |key, value|
        next if value.to_s.strip.empty?

        books = books.select { |book| book[key].to_s.downcase.include?(value.downcase) }
      end
      books
    end

    private

    def ensure_librarian!(user)
      raise StandardError, 'forbidden' unless user && user[:role] == 'librarian'
    end

    def validate_book!(attrs)
      required = %i[title author genre isbn total_copies]
      missing = required.select { |key| attrs[key].to_s.strip.empty? }
      raise ArgumentError, "missing fields: #{missing.join(', ')}" if missing.any?
    end
  end
end
