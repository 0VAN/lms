# frozen_string_literal: true

class DashboardsController < ApplicationController
  before_action -> { require_user! }

  def show
    dashboard = Library::Registry.dashboard_service.for_user(current_user)
    render json: dashboard
  end
end
