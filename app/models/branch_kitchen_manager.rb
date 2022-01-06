class BranchKitchenManager < ApplicationRecord
  belongs_to :user
  belongs_to :branch

  def self.create_branch_kitchen_managers(user, branch)
  	branch.reject!(&:empty?) rescue nil
    if branch.class != Array
      branch = branch.split(",")
    end
  	branch.each do |id|
  		branch_transport = new(user_id: user.id, branch_id:id)
    	branch_transport.save!
    	!branch_transport.id.nil? ? branch_transport : false
  	end
  end
end
