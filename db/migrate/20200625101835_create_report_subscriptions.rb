class CreateReportSubscriptions < ActiveRecord::Migration[5.2]
  def change
    create_table :report_subscriptions do |t|
      t.float :fee, null: false
      t.references :country, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
