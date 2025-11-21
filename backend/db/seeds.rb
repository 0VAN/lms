# frozen_string_literal: true

require_relative '../config/environment'

preset = (ENV['SEED_PRESET'] || :demo).to_sym

Library::Registry.reset!(seed: true, preset: preset)

store = Library::Registry.store
puts "Seeded in-memory store with preset '#{preset}': #{store.users.count} users, #{store.books.count} books, #{store.all_borrowings.count} borrowings."
