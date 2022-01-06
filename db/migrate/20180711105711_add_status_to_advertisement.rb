class AddStatusToAdvertisement < ActiveRecord::Migration[5.1]
  def change
    add_column :advertisements, :place, :string
    add_column :advertisements, :position, :string
    add_column :advertisements, :title, :string
    add_column :advertisements, :description, :string
    add_column :advertisements, :amount, :float
    add_column :advertisements, :from_date, :string
    add_column :advertisements, :to_date, :string
    add_column :advertisements, :status, :string
    add_reference :advertisements, :add_request, foreign_key: true
    add_reference :advertisements, :branch, foreign_key: true
    add_column :advertisements, :transaction_id, :string
  end
end
