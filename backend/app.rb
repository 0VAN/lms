# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/json'
require 'json'
require_relative 'lib/library'

module Library
  # Sinatra application exposing the Library API.
  class App < Sinatra::Base
    helpers Sinatra::JSON

    configure do
      enable :logging
      reset_store!
    end

    def self.reset_store!
      store = DataStore.new
      set :store, store
      set :auth_service, Authentication.new(store)
      set :book_service, BookManagement.new(store)
      set :borrowing_service, Borrowing.new(store)
      set :dashboard_service, Dashboard.new(store)
    end

    before do
      content_type :json
    end

    helpers do
      def auth_header
        request.env['HTTP_AUTHORIZATION']&.split&.last
      end

      def current_user
        @current_user ||= settings.auth_service.current_user(auth_header)
      end

      def require_user!
        halt 401, json(error: 'unauthorized') unless current_user
      end

      def require_role!(role)
        require_user!
        halt 403, json(error: 'forbidden') unless current_user[:role] == role
      end

      def parsed_body
        request.body.rewind
        raw = request.body.read
        raw.empty? ? {} : JSON.parse(raw, symbolize_names: true)
      rescue JSON::ParserError
        halt 400, json(error: 'invalid json')
      end
    end

    error StandardError do
      status 400
      json error: env['sinatra.error'].message
    end

    post '/register' do
      user = settings.auth_service.register(**parsed_body)
      status 201
      json user
    end

    post '/login' do
      auth = settings.auth_service.login(parsed_body[:email], parsed_body[:password])
      halt 401, json(error: 'invalid credentials') unless auth

      json auth
    end

    post '/logout' do
      require_user!
      settings.auth_service.logout(auth_header)
      json success: true
    end

    get '/books' do
      books = settings.book_service.search(
        title: params['title'],
        author: params['author'],
        genre: params['genre']
      )
      json books
    end

    post '/books' do
      require_role!('librarian')
      book = settings.book_service.add_book!(current_user, parsed_body)
      status 201
      json book
    end

    put '/books/:id' do
      require_role!('librarian')
      book = settings.book_service.update_book!(current_user, params[:id].to_i, parsed_body)
      json book
    end

    patch '/books/:id' do
      require_role!('librarian')
      book = settings.book_service.update_book!(current_user, params[:id].to_i, parsed_body)
      json book
    end

    delete '/books/:id' do
      require_role!('librarian')
      book = settings.book_service.delete_book!(current_user, params[:id].to_i)
      json book
    end

    post '/books/:id/borrow' do
      require_role!('member')
      borrow = settings.borrowing_service.borrow_book!(current_user, params[:id].to_i)
      status 201
      json borrow
    end

    post '/borrowings/:id/return' do
      require_role!('librarian')
      borrowing = settings.borrowing_service.return_book!(current_user, params[:id].to_i)
      json borrowing
    end

    get '/borrowings' do
      require_user!
      json settings.borrowing_service.borrowings_for(current_user)
    end

    get '/dashboard' do
      require_user!
      json settings.dashboard_service.for_user(current_user)
    end

    get '/health' do
      json ok: true
    end

    run! if app_file == $PROGRAM_NAME
  end
end
