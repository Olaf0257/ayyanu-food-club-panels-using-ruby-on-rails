class Brand < ApplicationRecord
  belongs_to :user
  belongs_to :restaurant

  def self.search(condition)
     where("name like ?", "#{condition}%")
  end
end
