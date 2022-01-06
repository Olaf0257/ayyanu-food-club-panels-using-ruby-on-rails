class CreateUserAndDeliveryCompanyShiftJoinTable < ActiveRecord::Migration[5.2]
  def change
    create_table :delivery_company_shifts_users, id: false do |t|
      t.belongs_to :delivery_company_shift, index: true, null: false
      t.belongs_to :user, index: true, null: false

      t.timestamps
    end
  end
end
