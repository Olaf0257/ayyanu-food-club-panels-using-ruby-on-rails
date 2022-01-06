class ChangeIsRejectedToEnterprises < ActiveRecord::Migration[5.2]
  def change
    change_column_default :enterprises, :is_rejected, false
    change_column_default :enterprises, :is_approved, false
  end
end
