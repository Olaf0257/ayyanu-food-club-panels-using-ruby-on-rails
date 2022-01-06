class Image < ApplicationRecord
  belongs_to :restaurant

  def as_json(options = {})
    super(options.merge(except: [:created_at, :updated_at, :id, :restaurant_id]))
  end
end
