# frozen_string_literal: true

module Library
  # Simple registry to share the in-memory store and services across controllers.
  module Registry
    class << self
      attr_reader :store, :auth_service, :book_service, :borrowing_service, :dashboard_service

      def reset!(seed: ENV['SEED_SAMPLE_DATA'] || ENV['SEED_PRESET'], preset: ENV['SEED_PRESET'])
        @store = DataStore.new
        @store.seed_sample_data!(preset: (preset || :demo)) if truthy?(seed)
        @auth_service = Authentication.new(@store)
        @book_service = BookManagement.new(@store)
        @borrowing_service = Borrowing.new(@store)
        @dashboard_service = Dashboard.new(@store)
      end

      private

      def truthy?(value)
        return false if value.nil?

        normalized = value.to_s.strip
        return false if normalized.empty? || %w[false 0].include?(normalized.downcase)

        true
      end
    end
  end
end
