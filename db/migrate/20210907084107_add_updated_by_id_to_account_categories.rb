class AddUpdatedByIdToAccountCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :account_categories, :updated_by_id, :integer
  end
end
