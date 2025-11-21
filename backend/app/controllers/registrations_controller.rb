# frozen_string_literal: true

class RegistrationsController < ApplicationController
  def create
    user = Library::Registry.auth_service.register(**registration_params.symbolize_keys)
    render json: user, status: :created
  end

  private

  def registration_params
    params.permit(:email, :password, :role)
  end
end
