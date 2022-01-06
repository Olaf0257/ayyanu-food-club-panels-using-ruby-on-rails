class CreateIous < ActiveRecord::Migration[5.1]
  def change
    create_table :ious do |t|
      t.references :order, foreign_key: true
      t.references :user, foreign_key: true
      t.string :transporter_id
      t.float :paid_amount
      t.boolean :is_received ,default: false

      t.timestamps
    end
  end
end
