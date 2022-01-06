class AddAdminOfferIdToOffers < ActiveRecord::Migration[5.2]
  def change
    add_reference :offers, :admin_offer, foreign_key: true, index: true
  end
end
