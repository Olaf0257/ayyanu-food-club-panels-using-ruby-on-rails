class AddInfluencerToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :influencer, :boolean, null: false, default: false
  end
end
