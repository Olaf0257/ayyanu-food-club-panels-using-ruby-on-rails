class Kds < ApplicationRecord

	serialize :country_ids, Array
	serialize :branch_ids, Array


	def countries
		Country.where(id: self.country_ids)
	end


	def branches
		Branch.where(id: self.branch_ids)
	end

	def station
		Station.find_by(id: self.station_id).name rescue ""
	end

end
