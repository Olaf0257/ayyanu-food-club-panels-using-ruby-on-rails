class CardType < ApplicationRecord
	belongs_to :updated_by, class_name: "User"
end
