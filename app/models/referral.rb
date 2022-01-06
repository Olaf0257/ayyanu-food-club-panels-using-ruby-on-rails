class Referral < ApplicationRecord
  belongs_to :user
  validates :email, presence: true, uniqueness: { scope: :email }

  def as_json(options = {})
    super(options.merge(only: [:email], methods: [:name]))
  end

  def name
    User.find_by(email: email)&.name.to_s
  end
end
