class AddAccountTypeIdToAccountCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :account_categories, :account_type_id, :integer
  end
end
