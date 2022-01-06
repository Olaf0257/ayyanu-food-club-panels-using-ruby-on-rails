class CreateTransporterTimings < ActiveRecord::Migration[5.2]
  def change
    create_table :transporter_timings do |t|
      t.references :user, foreign_key: true, null: false
      t.datetime :login_time
      t.datetime :logout_time

      t.timestamps
    end
  end
end
