class AddCrAndCprColumnsToBranches < ActiveRecord::Migration[5.2]
  def change
    add_column :branches, :cr_document, :string
    add_column :branches, :cpr_document, :string
  end
end
