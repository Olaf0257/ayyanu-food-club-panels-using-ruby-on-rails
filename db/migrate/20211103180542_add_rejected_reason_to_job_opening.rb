class AddRejectedReasonToJobOpening < ActiveRecord::Migration[5.2]
  def change
    add_column :job_openings, :rejected_reason, :string
  end
end
