class User < ActiveRecord::Base

  require 'securerandom'

  include Redis::Objects

  has_one :email_verification
  belongs_to :university

  after_save :ensure_is_in_correct_set

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
    user_ids = compatible_users.difference(history, matches, admired).sample(number)
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

  def compatible_users
    # users that the current user might be interested in
    if !@identifiers
      @identifiers = Redis::Set.new(targetting_identifier) #create or retrieve
    end
    @identifiers
  end

  # auth

  def send_verification_email
    self.email_verification = EmailVerification.generate! self
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

  def age
    dob = date_of_birth
    now = Time.now.utc.to_date
    now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
  end

  def status
    relationship_status
  end

  def matched_with? user
    matches.member? user.id
  end

  #private

    def fetch_and_sort ids
      users = User.where(id:ids)
      map = Hash[ids.map.with_index.to_a]
      users.to_a.sort_by! {|user| map[user.id.to_s]}
      users
    end

    def ensure_is_in_correct_set
      if self.gender_changed? || self.interested_in_changed?
        puts "Here #{self.id}: #{Redis::Set.new(targeted_by_identifier).to_a}"
        Redis::Set.new(old_targeted_by_identifier).delete(id) # move out of old
        Redis::Set.new(targeted_by_identifier) << id # and into new
        puts "Here: #{Redis::Set.new(targeted_by_identifier).to_a}"
      end
    end

    def targetting_identifier
      # find people who have their targeted_by identifier as this
      "#{university_id}-#{self[:interested_in]}-#{self[:gender]}"
    end

    def targeted_by_identifier
      # be found by people who have their targetting identifier as this.
      "#{university_id}-#{self[:gender]}-#{self[:interested_in]}"
    end

    def old_targeted_by_identifier
      "#{university_id}-#{User.genders[gender_was]}-#{User.genders[interested_in_was]}"
    end

end
