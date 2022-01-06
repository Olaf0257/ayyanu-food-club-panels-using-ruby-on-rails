class CateringSchedule < ApplicationRecord
  belongs_to :pos_check
  belongs_to :branch
end
