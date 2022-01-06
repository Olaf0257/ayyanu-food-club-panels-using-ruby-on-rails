class CreateServicefees < ActiveRecord::Migration[5.1]
  def change
    create_table :servicefees do |t|
      t.float :report_subscribe_fee

      t.timestamps
    end
  end
end
