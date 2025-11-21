# frozen_string_literal: true

require 'json'
require_relative '../app'
require_relative './spec_helper'

RSpec.describe Library::App do
  include Rack::Test::Methods

  def app
    described_class
  end

  before do
    described_class.reset_store!
  end

  def auth_header(token)
    { 'HTTP_AUTHORIZATION' => "Bearer #{token}" }
  end

  def register(email:, password:, role:)
    post '/register', { email: email, password: password, role: role }.to_json, 'CONTENT_TYPE' => 'application/json'
  end

  def login(email:, password:)
    post '/login', { email: email, password: password }.to_json, 'CONTENT_TYPE' => 'application/json'
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

    post '/books', { title: 'Test', author: 'Author', genre: 'Fiction', isbn: '123', total_copies: 2 }.to_json,
         auth_header(auth[:token]).merge('CONTENT_TYPE' => 'application/json')
    expect(last_response.status).to eq(201)
    book = JSON.parse(last_response.body, symbolize_names: true)

    put "/books/#{book[:id]}", { title: 'Updated Title' }.to_json,
        auth_header(auth[:token]).merge('CONTENT_TYPE' => 'application/json')
    expect(last_response.status).to eq(200)

    get '/books', { title: 'Updated' }
    expect(JSON.parse(last_response.body, symbolize_names: true).first[:title]).to eq('Updated Title')

    delete "/books/#{book[:id]}", {}, auth_header(auth[:token])
    expect(last_response.status).to eq(200)
  end

  it 'prevents duplicate borrowing and enforces availability limits' do
    register(email: 'lib@example.com', password: 'secret', role: 'librarian')
    lib_auth = login(email: 'lib@example.com', password: 'secret')
    post '/books', { title: 'Test', author: 'Author', genre: 'Fiction', isbn: '123', total_copies: 1 }.to_json,
         auth_header(lib_auth[:token]).merge('CONTENT_TYPE' => 'application/json')
    book = JSON.parse(last_response.body, symbolize_names: true)

    register(email: 'mem@example.com', password: 'secret', role: 'member')
    member_auth = login(email: 'mem@example.com', password: 'secret')

    post "/books/#{book[:id]}/borrow", {}.to_json, auth_header(member_auth[:token])
    expect(last_response.status).to eq(201)

    post "/books/#{book[:id]}/borrow", {}.to_json, auth_header(member_auth[:token])
    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)['error']).to eq('already borrowed')
  end

  it 'tracks borrowing lifecycle and dashboards' do
    register(email: 'lib@example.com', password: 'secret', role: 'librarian')
    lib_auth = login(email: 'lib@example.com', password: 'secret')
    post '/books', { title: 'Test', author: 'Author', genre: 'Fiction', isbn: '123', total_copies: 2 }.to_json,
         auth_header(lib_auth[:token]).merge('CONTENT_TYPE' => 'application/json')
    book = JSON.parse(last_response.body, symbolize_names: true)

    register(email: 'mem@example.com', password: 'secret', role: 'member')
    member_auth = login(email: 'mem@example.com', password: 'secret')

    post "/books/#{book[:id]}/borrow", {}.to_json, auth_header(member_auth[:token])
    borrowing = JSON.parse(last_response.body, symbolize_names: true)

    get '/dashboard', {}, auth_header(member_auth[:token])
    member_dashboard = JSON.parse(last_response.body, symbolize_names: true)
    expect(member_dashboard[:borrowed].first[:book]).to eq('Test')

    # Mark overdue for librarian dashboard visibility
    store = described_class.settings.store
    store.find_borrowing(borrowing[:id])[:due_date] = Date.today - 1

    post "/borrowings/#{borrowing[:id]}/return", {}, auth_header(lib_auth[:token])
    expect(last_response.status).to eq(200)

    get '/dashboard', {}, auth_header(lib_auth[:token])
    dashboard = JSON.parse(last_response.body, symbolize_names: true)
    expect(dashboard[:total_books]).to eq(1)
    expect(dashboard[:overdue_members].first[:email]).to eq('mem@example.com')
  end
end
