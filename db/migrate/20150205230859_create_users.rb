class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|

      t.string :access_token
      t.string :name
      t.text   :description
      t.string :email
      t.string :course
      t.date   :date_of_birth
      t.string :snapchat_username
      t.string :photo_urls
      t.string :relationship_status

      t.integer :account_status, default: 0, null: false
      t.integer :interested_in, default: 0, null: false
      t.integer :gender, default: 0, null: false

      t.integer :university_id
      t.integer :fb_id
      t.string  :fb_access_token


      t.timestamps null: false
    end
  end
end
