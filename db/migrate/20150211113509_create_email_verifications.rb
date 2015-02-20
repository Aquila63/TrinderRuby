class CreateEmailVerifications < ActiveRecord::Migration
  def change
    create_table :email_verifications do |t|

      t.timestamps null: false
    end
  end
end
