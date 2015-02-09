class EmailVerificationsController < ApplicationController
  def create
    verification = EmailVerification.find_by(code: params[:code])
    if !verification
      # todo
    end
    verification.user.verify!
    # show confirmation
  end
end
