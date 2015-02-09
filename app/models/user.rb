class User < ActiveRecord::Base

  require 'securerandom'

  include Redis::Objects
  serialize :photo_urls

  enum relationship_status: [:single, :its_complicated, :in_a_relationship]
  enum account_status: [:unverified, :verified]
  enum gender: [:male, :female]
  enum interested_in: [:males, :females]

  set :history
  set :admirers
  set :admired # people you've admired
  set :matches

  def random_valid_users(number)
    user_ids = self.compatible_users.difference(history, matches, admired).sample(number)
    user_ids -= [id.to_s] # remove yourself. Not ideal
    user_ids = (admirers.to_a + user_ids).uniq
    users = User.where(id:user_ids)
    map = Hash[user_ids.map.with_index.to_a]
    users.to_a.sort_by! {|user| map[user.id.to_s]}
    users
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

  def generate_access_token
    token = ""
    begin
      token = SecureRandom.urlsafe_base64(10)
    end while User.exists?(access_token: token)
    self.access_token = token
    self.save
  end

  def set_visible
    Redis::Set.new(targeted_by_identifier) << id
  end

  def set_invisible
    Redis::Set.new(targeted_by_identifier).delete(id)
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
end
