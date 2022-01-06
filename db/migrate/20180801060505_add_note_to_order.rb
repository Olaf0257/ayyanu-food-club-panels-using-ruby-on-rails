class AddNoteToOrder < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :note, :string
  end
end
