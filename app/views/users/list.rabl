collection @users
attributes :id, :name, :description, :gender, :interested_in, :status, :course, :age, :photo_urls

node :snapchat_username, if: lambda {|user| @user.matched_with?(user) } do |user|
  user.snapchat_username
end