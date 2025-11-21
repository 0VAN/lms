# frozen_string_literal: true

class ApplicationController < ActionController::API
  rescue_from StandardError, with: :render_error

  private

  def render_error(error)
    Rails.logger.error(error.full_message)
    status_code = error.is_a?(ActionController::ParameterMissing) ? :bad_request : :bad_request
    render json: { error: error.message }, status: status_code
  end

  def auth_header
    request.headers['Authorization']&.split&.last
  end

  def current_user
    @current_user ||= Library::Registry.auth_service.current_user(auth_header)
  end

  def require_user!
    render json: { error: 'unauthorized' }, status: :unauthorized unless current_user
  end

  def require_role!(role)
    return render json: { error: 'unauthorized' }, status: :unauthorized unless current_user
    render json: { error: 'forbidden' }, status: :forbidden unless current_user[:role] == role
  end
end
