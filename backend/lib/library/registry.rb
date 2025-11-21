# frozen_string_literal: true

module Library
  # Simple registry to share the in-memory store and services across controllers.
  module Registry
    class << self
      attr_reader :store, :auth_service, :book_service, :borrowing_service, :dashboard_service

      def reset!(seed: ENV['SEED_SAMPLE_DATA'])
        @store = DataStore.new
        @store.seed_sample_data! if seed
        @auth_service = Authentication.new(@store)
        @book_service = BookManagement.new(@store)
        @borrowing_service = Borrowing.new(@store)
        @dashboard_service = Dashboard.new(@store)
      end
    end
  end
end
