class EmailVerification < ActiveRecord::Base

  belongs_to :user

  require 'securerandom'

  def self.generate! user
    verification = EmailVerification.new
    verification.user = user
    verification.generate_code
    verification.send!
    verification
  end


  private

    def send!
      # todo send email
    end

    def generate_code
      code = ""
      begin
        code = SecureRandom.urlsafe_base64(20)
      end while EmailVerification.exists?(code: code)
      self.code = code
      self.save
    end

end
