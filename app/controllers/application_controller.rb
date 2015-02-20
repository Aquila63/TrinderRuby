class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  def check_authentication
    @user = User.find_by(access_token: params[:access_token])
    if !@user || !params[:access_token]
      render json: {error: "Session expired. Please login again"}, status: 401
    end
  end
end
