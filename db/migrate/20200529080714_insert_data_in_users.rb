class InsertDataInUsers < ActiveRecord::Migration[5.1]
  def self.up
    Role.create(:role_name=>'Admin')
  end
end
