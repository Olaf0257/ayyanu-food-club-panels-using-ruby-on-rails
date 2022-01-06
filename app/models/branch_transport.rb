class BranchTransport < ApplicationRecord
  belongs_to :user
  belongs_to :branch

  def self.create_branch_transporters(user, branch)
    branch_transport = new(user_id: user.id, branch_id: branch.id)
    branch_transport.save!
    !branch_transport.id.nil? ? branch_transport : false
  end

  # Only for Test create transporter
  def self.created_branch_transporter(branch_id, user_id)
    transporter = new(branch_id: branch_id, user_id: user_id)
    transporter.save!
    !transporter.id.nil? ? { code: 200, result: transporter } : { code: 400, result: transporter.errors.full_messages.join(", ") }
  end
end
