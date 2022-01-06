class CreateSocialAuths < ActiveRecord::Migration[5.1]
  def change
    create_table :social_auths do |t|
      t.string :provider_id
      t.string :provider_type
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
