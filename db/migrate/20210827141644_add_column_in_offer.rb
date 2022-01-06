class AddColumnInOffer < ActiveRecord::Migration[5.2]
  def change
    add_column :offers, :include_in_pos, :boolean, default: true
    add_column :offers, :include_in_app, :boolean, default: true
  end
end
