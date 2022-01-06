class Auth < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  extend Devise::Models
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  belongs_to :user
  has_many :server_sessions, dependent: :destroy

  # # enum role: [:customer, :business]
  # validates :role, inclusion: { in: %w(customer business)}
  # # validates :role, inclusion: { in: [:customer, :business] }
  # before_create :ensure_authentication_token # i.e. api_key
  validates_uniqueness_of :user_id

  def ensure_authentication_token
    server_token = generate_access_token
    # self.auths.last.last_active_at = Time.now
  end

  def generate_access_token
    loop do
      token = Devise.friendly_token
      break token unless ServerSession.where(server_token: token).first
    end
  end

  def email_required?
    false
  end

  def email_changed?
    false
  end

  # use this instead of email_changed? for rails >= 5.1
  def will_save_change_to_email?
    false
  end

  def self.create_user_password(user, password, role)
    password = new(user_id: user.id, role: role, password: password, password_confirmation: password)
    password.save
    password
  end

  def self.create_delivery_company_user_password(user, password, role)
    password = new(user_id: user.id, role: role, password: password, password_confirmation: password)
    password.save
    password
  end

  def self.update_otp(user, otp)
    user.auths.first.update(otp: otp, reset_password_token: user.generate_password_recovery_token(user.id, otp))
  end

  def self.with_password_token(user_id, token)
    find_by(user_id: user_id, reset_password_token: token)
  end

  def self.update_password(auth, new_password)
    auth.update(password: new_password, reset_password_sent_at: nil, reset_password_token: nil)
  end

  def generate_password_recovery_token(user_id, otp)
    encode_token("#{user_id}otp#{otp}")
  end

  def self.create_role_user_password(user, password)
    password = new(user_id: user.id, password: password, password_confirmation: password)
    password.save
    password
  end
end
