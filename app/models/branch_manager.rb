class BranchManager < ApplicationRecord
  belongs_to :branch
  belongs_to :user

  def self.create_branch_managers(user, branch)
    branch_transport = new(user_id: user.id, branch_id: branch.id)
    branch_transport.save!
    !branch_transport.id.nil? ? branch_transport : false
  end
end
