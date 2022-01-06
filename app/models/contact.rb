class Contact < ApplicationRecord
    belongs_to :country, optional: true
end
