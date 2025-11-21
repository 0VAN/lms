# frozen_string_literal: true

require_relative 'data_store'

module Library
  # Handles user lifecycle and token management.
  class Authentication
    ALLOWED_ROLES = %w[librarian member].freeze

    def initialize(store)
      @store = store
    end

    def register(email:, password:, role: 'member')
      raise ArgumentError, 'role must be librarian or member' unless ALLOWED_ROLES.include?(role)
      raise ArgumentError, 'email required' if email.to_s.strip.empty?
      raise ArgumentError, 'password required' if password.to_s.strip.empty?
      raise StandardError, 'email taken' if @store.find_user_by_email(email)

      user = @store.create_user(email: email, password: password, role: role)
      sanitize_user(user)
    end

    def login(email, password)
      user = @store.find_user_by_email(email)
      return nil unless user && user[:password] == password

      token = @store.store_token(user[:id])
      { token: token, user: sanitize_user(user) }
    end

    def logout(token)
      @store.delete_token(token)
    end

    def current_user(token)
      user_id = @store.token_owner(token)
      sanitize_user(@store.find_user(user_id)) if user_id
    end

    private

    def sanitize_user(user)
      return unless user

      user.reject { |k, _| k == :password }
    end
  end
end
