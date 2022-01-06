class AddCreatedByIdToFamilyDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :family_details, :created_by_id, :integer
  end
end
