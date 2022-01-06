class CreateOrders < ActiveRecord::Migration[5.1]
  def change
    create_table :orders do |t|
    	t.string :fname
    	t.string :lname
    	t.string :area
    	t.string :address_type
    	t.string :block
    	t.string :street
    	t.string :building
    	t.string :floor
    	t.string :apartment_number
    	t.string :additional_direction
    	t.string :contact
    	t.string :landline
    	t.string :transection_id
    	t.string :total_amount
    	t.references :cart, foreign_key: true
    	t.references :branch, foreign_key: true
      t.timestamps
    end
  end
end
