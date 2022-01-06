class AddOpeningTimingToBranch < ActiveRecord::Migration[5.1]
  def change
    add_column :branches, :opening_timing, :string
    add_column :branches, :closing_timing, :string
  end
end
