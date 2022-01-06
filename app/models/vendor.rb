class Vendor < ApplicationRecord
	STATUS = [["Active",true],['InActive',false]]
  belongs_to :user, optional: true
  belongs_to :country, optional: true
  belongs_to :area, class_name: "CoverageArea"
  attr_accessor :first_name, :middle_name, :last_name, :email

  scope :active, -> { where(status: true) }
end
