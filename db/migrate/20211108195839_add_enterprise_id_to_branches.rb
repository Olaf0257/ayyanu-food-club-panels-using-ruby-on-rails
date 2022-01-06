class AddEnterpriseIdToBranches < ActiveRecord::Migration[5.2]
  def change
    add_column :branches, :enterprise_id, :integer
  end
end
