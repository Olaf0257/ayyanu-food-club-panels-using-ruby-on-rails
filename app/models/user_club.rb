class UserClub < ApplicationRecord
  belongs_to :user
  belongs_to :club_sub_category

  def as_json(options = {})
    super(options.merge(except: [:created_at, :updated_at, :user_id]))
  end

  def self.new_club_add(user, sub_category)
    club = new(user_id: user.id, club_sub_category_id: sub_category.id)
    club.save!
    !club.id.nil? ? { code: 200, result: club } : { code: 400, result: club.errors.full_messages.join(", ") }
    # club
  end

  def self.find_user_club_data(sub_category, user)
    find_by(user_id: user.id, club_sub_category_id: sub_category.id)
  end
end
