class RemoveCountryFromOverGroup < ActiveRecord::Migration[5.2]
  def change
    remove_reference :over_groups, :country, foreign_key: true
  end
end
