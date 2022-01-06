class AddUpdatedByIdToCardTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :card_types, :updated_by_id, :integer
  end
end
