class User < ActiveRecord::Base

  require 'securerandom'

  include Redis::Objects

  has_one :email_verification
  belongs_to :university

  before_save :ensure_is_in_correct_set

  serialize :photo_urls
  enum account_status: [:unverified, :verified]
  enum gender: [:male, :female]
  enum interested_in: [:males, :females]

  set :history
  set :admirers
  set :admired # people you've admired
  set :matches

  # fetch methods

  def random_valid_users(number)
    user_ids = self.compatible_users.difference(history, matches, admired).sample(number)
    user_ids -= [id.to_s] # remove yourself. Not ideal
    user_ids = (admirers.to_a + user_ids).uniq
    fetch_and_sort user_ids
  end

  def sorted_history
    user_ids = @user.history.to_a
    fetch_and_sort user_ids
  end

  def sorted_matches
    user_ids = @user.matches.to_a
    fetch_and_sort user_ids
  end

  def compatible_users
    # users that the current user might be interested in
    if !@identifiers
      @identifiers = Redis::Set.new(targetting_identifier) #create or retrieve
    end
    @identifiers
  end

  def like user
    if admirers.include? user.id
      # user is reciprocating a like. Create a match
      user.matches << self.id
      self.matches << user.id
      self.admirers.delete(user.id)
      user.admired.delete(self.id)
    else
      self.admired << user.id
      user.admirers << self.id
      self.history << user.id
    end
  end

  # auth

  def self.auth_using_facebook_access_token access_token
    fb = Koala::Facebook::API.new(access_token)
    fb_user = fb.get_object("me?fields=id")
    user = User.find_by(fb_id: fb_user["id"])
    if user
      # login and return details
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
    return user
  end

  def send_verification_email
    email_verification = EmailVerification.generate! self
  end

  # others and helpers

  def generate_access_token
    token = ""
    begin
      token = SecureRandom.urlsafe_base64(10)
    end while User.exists?(access_token: token)
    self.access_token = token
    self.save
  end

  def targeted_by_identifier
    # be found by people who have their targetting identifier as this.
    "#{university_id}-#{self[:gender]}-#{self[:interested_in]}"
  end

  def targetting_identifier
    # find people who have their targeted_by identifier as this
    "#{university_id}-#{self[:interested_in]}-#{self[:gender]}"
  end

  def age
    dob = date_of_birth
    now = Time.now.utc.to_date
    now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
  end

  def status
    relationship_status.humanize
  end

  def matched_with? user
    matches.member? user.id
  end

  private

    def fetch_and_sort ids
      users = User.where(id:ids)
      map = Hash[ids.map.with_index.to_a]
      users.to_a.sort_by! {|user| map[user.id.to_s]}
      users
    end

    def ensure_is_in_correct_set
      if self.gender_changed? || self.interested_in_changed?
        Redis::Set.new(targeted_by_identifier).delete(id) # move out of old
        Redis::Set.new(targeted_by_identifier) << id # and into new
      end
    end

end
