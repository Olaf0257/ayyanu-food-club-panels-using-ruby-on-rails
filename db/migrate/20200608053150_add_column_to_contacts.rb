class AddColumnToContacts < ActiveRecord::Migration[5.1]
  def change
    add_column :contacts, :country_id, :integer
  end
end
