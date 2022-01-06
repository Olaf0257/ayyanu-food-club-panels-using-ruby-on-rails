class AddPrinterIpToStations < ActiveRecord::Migration[5.2]
  def change
    add_column :stations, :printer_ip, :string
  end
end
