class AddRejectReasonToEnterprises < ActiveRecord::Migration[5.2]
  def change
    add_column :enterprises, :reject_reason, :string
  end
end
