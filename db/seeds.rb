User.destroy_all
User.redis.flushdb

@user = User.new
@user.university_id = 1
@user.generate_access_token
@user.access_token = "bTmunLMfMu-J-Q" # tmp
@user.gender = :male
@user.interested_in = :females
@user.save
puts "Access Token: #{@user.access_token}"

def self.demo_photo
  length = 5
  slug = rand(36**length).to_s(36) #random
  Faker::Avatar.image(slug, "300x300")
end

80.times do
  user = User.new
  user.university_id = 1
  user.name = Faker::Name.name
  user.description = Faker::Lorem.paragraph
  user.email = Faker::Internet.email(user.name)
  user.photo_urls = [demo_photo, demo_photo, demo_photo]
  user.relationship_status = ["Single","It's complicated", "In a relationship"][Random.rand(3)]
  user.gender = Random.rand(2)
  user.interested_in = Random.rand(2)
  user.date_of_birth = (18.years + rand(10.years)).seconds.ago
  user.course = "Computer Science"
  user.snapchat_username = Faker::Internet.user_name
  user.save
end
