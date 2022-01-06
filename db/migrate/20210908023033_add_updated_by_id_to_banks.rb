class AddUpdatedByIdToBanks < ActiveRecord::Migration[5.2]
  def change
    add_column :banks, :updated_by_id, :integer
    add_column :banks, :city_id, :integer
    add_column :banks, :country_id, :integer
  end
end
