class Notification < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :receiver, class_name: "User", foreign_key: "receiver_id", optional: true
  belongs_to :order, optional: true
  belongs_to :restaurant, optional: true
  belongs_to :delivery_company, optional: true
  # belongs_to :admin,optional: true
  include ActionView::Helpers::DateHelper

  def as_json(options = {})
    super(options.merge(except: [:updated_at, :created_at, :user_id, :receiver_id, :admin_id, :seen_by_admin], methods: [:address, :name, :logo, :received_at]))
  end

  def self.find_user_notifications(user, page, per_page)
    where(receiver_id: user.id).order("id DESC").paginate(page: page, per_page: per_page)
  end

  def address
    order.branch.address if order.present?
  end

  def name
    order.branch.restaurant.title if order.present?
  end

  def logo
    order.branch.restaurant.logo if order.present?
  end

  def received_at
    time_ago_in_words(created_at).gsub("about", "") + " ago"
  end

  def self.find_notification(user, notification_id)
    find_by(receiver_id: user.id, id: notification_id)
  end

  def self.find_all_unseen_notification(user)
    where("receiver_id = (?) and status = (?)", user.id, false)
  end
end
