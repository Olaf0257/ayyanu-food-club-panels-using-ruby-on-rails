class AddCountryCodeToJobPositions < ActiveRecord::Migration[5.2]
  def change
    add_column :job_openings, :country_code, :string
  end
end
