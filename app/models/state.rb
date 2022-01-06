class State < ApplicationRecord
  belongs_to :country, optional: true
  has_many :districts, dependent: :destroy

  validates :name, presence: true

  default_scope { order(:name) }
end
