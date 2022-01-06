class AddContactToFamilyDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :family_details, :contact, :string
  end
end
