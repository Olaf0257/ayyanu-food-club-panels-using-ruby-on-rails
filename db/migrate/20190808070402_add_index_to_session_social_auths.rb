class AddIndexToSessionSocialAuths < ActiveRecord::Migration[5.1]
  def change
  	add_index :social_auths, :provider_id
  	add_index :social_auths, :provider_type
  end
end
