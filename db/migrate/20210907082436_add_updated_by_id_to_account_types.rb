class AddUpdatedByIdToAccountTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :account_types, :updated_by_id, :integer
  end
end
