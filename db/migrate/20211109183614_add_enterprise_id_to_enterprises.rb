class AddEnterpriseIdToEnterprises < ActiveRecord::Migration[5.2]
  def change
    add_column :enterprises, :enterprise_id, :integer
  end
end
