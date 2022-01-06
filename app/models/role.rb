class Role < ApplicationRecord
  validates :role_name, presence: true, uniqueness: true, on: :create, on: :update
  has_many :role_privileges
  has_many :privileges, through: :role_privileges

  before_destroy do
    role_privileges.destroy_all
  end
end
