# frozen_string_literal: true

require 'json'
require_relative './spec_helper'

RSpec.describe 'Library Rails API' do
  include Rack::Test::Methods

  def app
    Rails.application
  end

  before do
    Library::Registry.reset!(seed: false)
  end

  def auth_header(token)
    { 'HTTP_AUTHORIZATION' => "Bearer #{token}" }
  end

  def register(email:, password:, role:)
    post '/register', { email: email, password: password, role: role }
  end

  def login(email:, password:)
    post '/login', { email: email, password: password }
    JSON.parse(last_response.body, symbolize_names: true)
  end

  it 'registers and authenticates users with roles' do
    register(email: 'lib@example.com', password: 'secret', role: 'librarian')
    expect(last_response.status).to eq(201)

    auth = login(email: 'lib@example.com', password: 'secret')
    expect(auth[:token]).to be_a(String)
    expect(auth[:user][:role]).to eq('librarian')
  end

  it 'allows librarians to manage books' do
    register(email: 'lib@example.com', password: 'secret', role: 'librarian')
    auth = login(email: 'lib@example.com', password: 'secret')

    post '/books', { title: 'Test', author: 'Author', genre: 'Fiction', isbn: '123', total_copies: 2 }, auth_header(auth[:token])
    expect(last_response.status).to eq(201)
    book = JSON.parse(last_response.body, symbolize_names: true)

    put "/books/#{book[:id]}", { title: 'Updated Title' }, auth_header(auth[:token])
    expect(last_response.status).to eq(200)

    get '/books', { title: 'Updated' }
    expect(JSON.parse(last_response.body, symbolize_names: true).first[:title]).to eq('Updated Title')

    delete "/books/#{book[:id]}", {}, auth_header(auth[:token])
    expect(last_response.status).to eq(200)
  end

  it 'prevents duplicate borrowing and enforces availability limits' do
    register(email: 'lib@example.com', password: 'secret', role: 'librarian')
    lib_auth = login(email: 'lib@example.com', password: 'secret')
    post '/books', { title: 'Test', author: 'Author', genre: 'Fiction', isbn: '123', total_copies: 1 }, auth_header(lib_auth[:token])
    book = JSON.parse(last_response.body, symbolize_names: true)

    register(email: 'mem@example.com', password: 'secret', role: 'member')
    member_auth = login(email: 'mem@example.com', password: 'secret')

    post "/books/#{book[:id]}/borrow", {}, auth_header(member_auth[:token])
    expect(last_response.status).to eq(201)

    post "/books/#{book[:id]}/borrow", {}, auth_header(member_auth[:token])
    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)['error']).to eq('already borrowed')
  end

  it 'tracks borrowing lifecycle and dashboards' do
    register(email: 'lib@example.com', password: 'secret', role: 'librarian')
    lib_auth = login(email: 'lib@example.com', password: 'secret')
    post '/books', { title: 'Test', author: 'Author', genre: 'Fiction', isbn: '123', total_copies: 2 }, auth_header(lib_auth[:token])
    book = JSON.parse(last_response.body, symbolize_names: true)

    register(email: 'mem@example.com', password: 'secret', role: 'member')
    member_auth = login(email: 'mem@example.com', password: 'secret')

    post "/books/#{book[:id]}/borrow", {}, auth_header(member_auth[:token])
    borrowing = JSON.parse(last_response.body, symbolize_names: true)

    get '/dashboard', {}, auth_header(member_auth[:token])
    member_dashboard = JSON.parse(last_response.body, symbolize_names: true)
    expect(member_dashboard[:borrowed].first[:book]).to eq('Test')

    store = Library::Registry.store
    store.find_borrowing(borrowing[:id])[:due_date] = Date.today - 1

    post "/borrowings/#{borrowing[:id]}/return", {}, auth_header(lib_auth[:token])
    expect(last_response.status).to eq(200)

    get '/dashboard', {}, auth_header(lib_auth[:token])
    dashboard = JSON.parse(last_response.body, symbolize_names: true)
    expect(dashboard[:total_books]).to eq(1)
    expect(dashboard[:overdue_members].first[:email]).to eq('mem@example.com')
  end
end
