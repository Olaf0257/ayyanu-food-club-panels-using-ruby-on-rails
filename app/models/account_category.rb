class AccountCategory < ApplicationRecord
 belongs_to :updated_by, class_name: "User"
 belongs_to :account_type
 belongs_to :restaurant

  def self.search(condition)
     where("name like ?", "#{condition}%")
  end
end
