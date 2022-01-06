class AddOtpToAuth < ActiveRecord::Migration[5.1]
  def change
    add_column :auths, :otp, :string
  end
end
