class CreateUserAndZoneJoinTable < ActiveRecord::Migration[5.2]
  def change
    create_table :users_zones, id: false do |t|
      t.belongs_to :user, index: true, null: false
      t.belongs_to :zone, index: true, null: false

      t.timestamps
    end
  end
end
