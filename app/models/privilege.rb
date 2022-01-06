class Privilege < ApplicationRecord
	validates :privilege_name, :presence => true
	has_many :role_privileges
	has_many :roles, through: :role_privileges
end