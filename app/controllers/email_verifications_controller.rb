class EmailVerificationsController < ApplicationController
  def create
    verification = EmailVerification.find_by(code: params[:code])
    if !verification
      # todo
    end
    verification.user.verified!
    verification.destroy
    # show confirmation
  end
end
