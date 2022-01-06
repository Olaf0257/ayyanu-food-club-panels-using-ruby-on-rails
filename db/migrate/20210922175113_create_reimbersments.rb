class CreateReimbersments < ActiveRecord::Migration[5.2]
  def change
    create_table :reimbersments do |t|
      t.string :name
    end
  end
end
