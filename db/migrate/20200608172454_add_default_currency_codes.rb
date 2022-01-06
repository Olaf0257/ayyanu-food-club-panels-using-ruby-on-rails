class AddDefaultCurrencyCodes < ActiveRecord::Migration[5.1]
  def up
    Country.where("id = 15")
      .update_all({currency_code: 'BD'})
      Country.where("id = 196")
      .update_all({currency_code: 'AED'})
      Country.where("id = 101")
      .update_all({currency_code: 'KWD'})
      Country.where("id = 98")
      .update_all({currency_code: 'JOD'})

  end
end
