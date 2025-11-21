# frozen_string_literal: true

class SessionsController < ApplicationController
  def create
    auth = Library::Registry.auth_service.login(params[:email], params[:password])
    return render json: { error: 'invalid credentials' }, status: :unauthorized unless auth

    render json: auth
  end

  def destroy
    return render json: { error: 'unauthorized' }, status: :unauthorized unless current_user

    Library::Registry.auth_service.logout(auth_header)
    render json: { success: true }
  end
end
