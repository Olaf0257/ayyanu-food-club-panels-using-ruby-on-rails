class RolePrivilege < ApplicationRecord
	validates :role_id, :presence => true
	validates :privilege_id, :presence => true
	belongs_to :role
	belongs_to :privilege
end