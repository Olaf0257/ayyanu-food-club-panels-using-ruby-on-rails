class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :branch
  def as_json(options = {})
    super(options.merge(except: [:created_at, :updated_at, :user_id, :branch_id]))
  end

  def self.add_favorite(user, branch_id)
    favorite = new(user_id: user.id, branch_id: branch_id)
    favorite.save!
    !favorite.id.nil? ? { code: 200, result: favorite } : { code: 400, result: favorite.errors.full_messages.join(", ") }
    # favorite.branch.update_attributes(:is_favorite=>true) if favorite.id
  end

  def self.find_favorite(user, branch_id)
    find_by(user_id: user, branch_id: branch_id)
  end
end
