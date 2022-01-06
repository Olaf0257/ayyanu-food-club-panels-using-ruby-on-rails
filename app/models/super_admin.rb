class SuperAdmin < ApplicationRecord
  # has_many :notifications, :dependent=>:destroy
  has_secure_password
  validates :email, uniqueness: { case_sensitive: false }

  def name
    admin_name
  end
end
