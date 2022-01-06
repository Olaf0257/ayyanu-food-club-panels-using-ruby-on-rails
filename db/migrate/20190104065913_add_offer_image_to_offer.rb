class AddOfferImageToOffer < ActiveRecord::Migration[5.1]
  def change
    add_column :offers, :offer_image, :string
  end
end
