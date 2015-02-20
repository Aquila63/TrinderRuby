class AuthenticationsController < ApplicationController
  before_action :check_authentication, only: :email

  def facebook
    user = User.auth_using_facebook_access_token params[:fb_access_token]
    if !user
      render json: {error: "Not a member of a valid university group"}
    else
      render json: {success: true}
    end
  end

  def email
    if University.valid_email? params[:email]
      @user.send_verification_email
      render json: {success: true, message:"Email Verification sent"}
    else
      render json: {error: "Not a valid university email address"}
    end
  end
end
