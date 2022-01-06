class AddPhoneToBrands < ActiveRecord::Migration[5.2]
  def change
    add_column :brands, :representative_phone, :string
    add_column :brands, :authorised_person_phone, :string
  end
end
