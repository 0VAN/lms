# frozen_string_literal: true

require_relative './spec_helper'

RSpec.describe 'Library::DataStore' do
  def build_store
    Library::DataStore.new
  end

  it 'registers and logs in users with roles' do
    store = build_store
    librarian = store.add_user(email: 'lib@example.com', password: 'secret', role: 'librarian')
    member = store.add_user(email: 'mem@example.com', password: 'secret', role: 'member')

    expect(librarian[:role]).to eq('librarian')
    expect(member[:role]).to eq('member')
    token = store.authenticate('lib@example.com', 'secret')
    expect(store.current_user(token)[:email]).to eq('lib@example.com')
  end

  it 'prevents duplicate book borrowing and tracks due dates' do
    store = build_store
    user = store.add_user(email: 'mem@example.com', password: 'secret', role: 'member')
    book = store.add_book(title: 'Test', author: 'Author', genre: 'Fiction', isbn: '123', total_copies: 1)

    borrow = store.borrow_book(user[:id], book[:id])
    expect(borrow[:due_date]).to eq(Date.today + 14)

    expect do
      store.borrow_book(user[:id], book[:id])
    end.to raise_error('already borrowed')
  end

  it 'allows librarians to manage books and returns' do
    store = build_store
    lib = store.add_user(email: 'lib@example.com', password: 'secret', role: 'librarian')
    member = store.add_user(email: 'mem@example.com', password: 'secret', role: 'member')
    book = store.add_book(title: 'Test', author: 'Author', genre: 'Fiction', isbn: '123', total_copies: 2)

    updated = store.update_book(book[:id], title: 'Updated')
    expect(updated[:title]).to eq('Updated')

    borrow = store.borrow_book(member[:id], book[:id])
    returned = store.mark_returned(borrow[:id])
    expect(returned[:returned_at]).to eq(Date.today)
    store.delete_book(book[:id])
    expect(store.books.empty?).to eq(true)
  end

  it 'searches books by fields and supports dashboards' do
    store = build_store
    lib = store.add_user(email: 'lib@example.com', password: 'secret', role: 'librarian')
    member = store.add_user(email: 'mem@example.com', password: 'secret', role: 'member')
    fiction = store.add_book(title: 'Mystery Tales', author: 'A. Author', genre: 'Fiction', isbn: '111', total_copies: 2)
    _nonfiction = store.add_book(title: 'Science 101', author: 'B. Writer', genre: 'Science', isbn: '222', total_copies: 1)

    results = store.search_books(title: 'Mystery')
    expect(results.first[:id]).to eq(fiction[:id])

    borrow = store.borrow_book(member[:id], fiction[:id])
    dashboard_lib = store.dashboard_for(lib)
    expect(dashboard_lib[:total_books]).to eq(2)
    expect(dashboard_lib[:total_borrowed]).to eq(1)

    dashboard_member = store.dashboard_for(member)
    expect(dashboard_member[:borrowed].first[:book]).to eq('Mystery Tales')
  end
end
