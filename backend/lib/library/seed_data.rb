# frozen_string_literal: true

module Library
  # Declarative seed data for quickly populating the in-memory store.
  module SeedData
    DEMO = {
      users: [
        { email: 'librarian@example.com', password: 'password', role: 'librarian' },
        { email: 'member@example.com', password: 'password', role: 'member' }
      ],
      books: [
        { title: 'The Ruby Way', author: 'Hal Fulton', genre: 'Programming', isbn: '9780321714633', total_copies: 3 },
        { title: 'Practical Object-Oriented Design', author: 'Sandi Metz', genre: 'Programming', isbn: '9780321721334', total_copies: 2 },
        { title: 'The Pragmatic Programmer', author: 'Andrew Hunt', genre: 'Programming', isbn: '9780135957059', total_copies: 1 }
      ],
      borrowings: [
        { user_email: 'member@example.com', book_isbn: '9780321714633', borrowed_at_offset_days: -1, loan_length_days: 14 },
        { user_email: 'member@example.com', book_isbn: '9780135957059', borrowed_at_offset_days: -20, loan_length_days: 14 }
      ]
    }.freeze

    TEST = {
      users: [
        { email: 'librarian@test.com', password: 'password', role: 'librarian' },
        { email: 'member@test.com', password: 'password', role: 'member' },
        { email: 'member2@test.com', password: 'password', role: 'member' }
      ],
      books: [
        { title: 'Clean Code', author: 'Robert C. Martin', genre: 'Programming', isbn: '9780132350884', total_copies: 2 },
        { title: 'Domain-Driven Design', author: 'Eric Evans', genre: 'Programming', isbn: '9780321125217', total_copies: 1 },
        { title: 'Refactoring', author: 'Martin Fowler', genre: 'Programming', isbn: '9780201485677', total_copies: 3 }
      ],
      borrowings: [
        { user_email: 'member@test.com', book_isbn: '9780132350884', borrowed_at_offset_days: -2, loan_length_days: 14 },
        { user_email: 'member@test.com', book_isbn: '9780321125217', borrowed_at_offset_days: -16, loan_length_days: 14 },
        { user_email: 'member2@test.com', book_isbn: '9780201485677', borrowed_at_offset_days: -1, returned_after_days: 1 }
      ]
    }.freeze

    PRESETS = {
      demo: DEMO,
      test: TEST
    }.freeze

    def self.fetch(preset)
      PRESETS[preset.to_sym] || DEMO
    end
  end
end
