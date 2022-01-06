class SocialAuth < ApplicationRecord
  belongs_to :user

  def self.create_social_auth(provider_id, provider_type, user)
    where(provider_id: provider_id, provider_type: provider_type, user: user.id).first_or_create
  end
end
