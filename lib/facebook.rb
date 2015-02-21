class Facebook
  
  def create_user_from_token access_token
    fb = Koala::Facebook::API.new(access_token)
    fb_user = fb.get_object("me?fields=id")
    user = User.find_by(fb_id: fb_user["id"])
    if user
      # login and return details
      # update details?
      return user
    end

    # check if part of valid university
    fb_groups = fb.get_connections("me","groups?fields=id")
    gids = fb_groups.map{|g| g["id"]}
    university = University.where(fb_group_id: gids).first

    if !university
      # user is unauthorized to use app. TODO check email?
      return nil
    end

    # create new user
    # need permissions - email, user_relationships, user_relationship_details, birthday
    fb_user = fb.get_object("me?fields=id,first_name,last_name,gender,birthday,email,relationship_status,interested_in")
    user = User.new
    user.university = university
    user.fb_id = fb_user["id"]
    user.name = "#{fb_user['first_name']} #{fb_user['last_name']}"
    user.gender = User.genders[fb_user["gender"]]
    user.date_of_birth = Date.parse(fb_user["birthday"])
    user.email = fb_user["email"]
    user.password = Devise.friendly_token.first(12)
    user.relationship_status = fb_user["relationship_status"].capitalize # what if fb_user["relationship_status"] is nil?

    # if only interested in one gender, set that as it. Otherwise just select opposite to current gender
    # TODO: tidy this up
    if fb_user["interested_in"] && fb_user["interested_in"].count != 1
      user.interested_in = user.male? ? :females : :males
    elsif fb_user["interested_in"]
      user.interested_in = fb_user["interested_in"] == "female" ? :females : :males
    end

    user.save
  end
end