class EventCountry < ApplicationRecord
  belongs_to :event
  belongs_to :country
end