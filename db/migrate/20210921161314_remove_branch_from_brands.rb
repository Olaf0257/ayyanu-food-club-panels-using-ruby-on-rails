class RemoveBranchFromBrands < ActiveRecord::Migration[5.2]
  def change
    remove_reference :brands, :branch, foreign_key: true
    add_column :brands, :representative, :string
    add_column :brands, :authorised_person, :string
  end
end
