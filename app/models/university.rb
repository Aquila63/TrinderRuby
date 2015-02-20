class University < ActiveRecord::Base

    has_many :users

    def valid_email? email
      domain = email.split("@").last
      return University.exists?(domain: domain)
    end
end
