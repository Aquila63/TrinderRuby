class AuthenticationsController < ApplicationController
  def create
    # either create from fb access token or email
    if params[:fb_access_token]
      user = User.auth_using_facebook_access_token params[:fb_access_token]
      if !user
        render json: {error: "Not a member of a valid university group"}
      else
        render json: {success: true}
      end
    elsif params[:email]
      # no password as this is simply verification
      # ensure valid access token first. TODO: tidy up?
      check_authentication
      if University.valid_email? params[:email]
        @user.send_verification_email
        render json: {success: true, message:"Email Verification sent"}
      else
        render json: {error: "Not a valid university email address"}
      end
    end
  end
end
