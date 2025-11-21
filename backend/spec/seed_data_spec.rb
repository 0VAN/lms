# frozen_string_literal: true

require 'json'
require 'date'
require_relative './spec_helper'

RSpec.describe 'Seed presets' do
  it 'loads the demo preset with predictable demo users/books' do
    store = Library::DataStore.new
    store.seed_sample_data!(preset: :demo)

    expect(store.users.map { |u| u[:email] }).to include('librarian@example.com', 'member@example.com')
    expect(store.books.count).to eq(3)
    expect(store.all_borrowings.count).to eq(2)
  end

  it 'loads the test preset with overdue and returned borrowings for dashboard validation' do
    store = Library::DataStore.new
    store.seed_sample_data!(preset: :test)

    overdue = store.all_borrowings.select { |b| b[:returned_at].nil? && b[:due_date] < Date.today }
    returned = store.all_borrowings.select { |b| b[:returned_at] }

    expect(store.users.map { |u| u[:email] }).to include('librarian@test.com', 'member@test.com')
    expect(store.books.count).to eq(3)
    expect(overdue).not_to be_empty
    expect(returned).not_to be_empty
  end
end
