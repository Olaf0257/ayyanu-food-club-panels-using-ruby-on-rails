class PosCheck < ApplicationRecord
  belongs_to :pos_table, optional: true
  belongs_to :branch, optional: true
  belongs_to :address, optional: true
  belongs_to :user, optional: true
  belongs_to :parant_pos_check, class_name: 'PosCheck', foreign_key: :parent_check_id, optional: true
  belongs_to :order_type, optional: true
  belongs_to :offer, optional: true
  has_many :pos_transactions, dependent: :destroy
  has_many :pos_unsaved_transactions, dependent: :destroy
  has_many :pos_unsaved_checks, dependent: :destroy
  has_many :merged_checks, class_name: 'PosCheck', foreign_key: :parent_check_id
  has_one :catering_schedule, dependent: :destroy
  belongs_to :driver, class_name: 'User', foreign_key: :driver_id, optional: true
  has_many :pos_payments, dependent: :destroy
  has_one :order, dependent: :destroy

  enum check_status: [:pending, :saved, :closed, :reopened, :reopened_pending]
  before_create :generate_unique_number

  after_commit :publish_to_channel

  default_scope -> { where(is_scheduled_check: false) }

  def generate_unique_number
    last_check = PosCheck.unscoped.all.order('created_at')&.last&.check_id.to_i
    self.check_id = last_check + 1
  end

  def time_lapsed
    time_diff = Time.current - created_at
    Time.at(time_diff.to_i.abs).utc.strftime "%H:%M:%S"
  end

  def self.removed_params
    ['id', 'created_at', 'updated_at', 'parent_check_id', 'address_id', 'user_id', 'saved_at', 'offer_id', 'is_scheduled_check', 'is_full_discount']
  end

  def self.save_check(pos_check, params = nil)
    pos_check_params = pos_check.as_json
    pos_unsaved_check = pos_check.pos_unsaved_checks
    PosCheck.removed_params.each {|k| pos_check_params.delete(k)}
    if pos_unsaved_check.present?
      pos_check.pos_unsaved_checks.update(pos_check_params)
    else
      pos_check.pos_unsaved_checks.create(pos_check_params)
    end
    if pos_check.pos_transactions.present?
      pos_check.pos_transactions.where(parent_pos_transaction_id: nil).each do |transaction|
        pos_transaction_params = transaction.as_json
        ['id', 'created_at', 'updated_at', 'parent_pos_transaction_id', 'shared_transaction_id'].each {|k| pos_transaction_params.delete(k)}
        pos_unsaved_transaction = pos_check.pos_unsaved_transactions.find_by(pos_transaction_id: transaction.id)
        if pos_unsaved_transaction.present?
          if pos_unsaved_transaction.is_deleted
            transaction.destroy
          else
            pos_unsaved_transaction.assign_attributes(pos_transaction_params)
          end
        else
          pos_unsaved_transaction = transaction.pos_unsaved_transactions.new(pos_transaction_params)
        end
        if pos_unsaved_transaction.save && transaction.reload.addon_pos_transactions.present?
          transaction.addon_pos_transactions.each do |addon|
            addon_params = addon.as_json
            ['id', 'created_at', 'updated_at', 'parent_pos_transaction_id', 'shared_transaction_id'].each {|k| addon_params.delete(k)}
            pos_unsaved_addon = pos_check.pos_unsaved_transactions.find_by(pos_transaction_id: addon.id)
            if pos_unsaved_addon.present?
              if pos_unsaved_addon.is_deleted
                addon.destroy
              else
                pos_unsaved_addon.assign_attributes(addon_params)
              end
            else
              pos_unsaved_addon = addon.pos_unsaved_transactions.new(addon_params)
              pos_unsaved_addon.parent_pos_unsaved_transaction_id = pos_unsaved_transaction.id
            end
            pos_unsaved_addon.save
          end
        end
      end
    end
    if pos_check.present? && params.present? && params[:with_driver_save].present? && params[:driver_id].present?
      pos_check.update(driver_id: params[:driver_id])
    end
    if pos_check.present? && pos_check.pos_payments.where(pending_delete: true).present?
      pos_check.pos_payments.where(pending_delete: true).destroy_all
    end
    if pos_check.present? && pos_check.pos_transactions.present?
      total_paid_amount = pos_check.pos_payments.pluck(:paid_amount).sum
      actual_paid_amount = pos_check.pos_transactions.pluck(:total_amount).sum
      if actual_paid_amount == total_paid_amount
        pos_check.update(check_status: 2, saved_at: Time.now)
      end
    end
    return pos_check if pos_check.present? && pos_check.pos_transactions.update_all(transaction_status: 'saved') && pos_check.update(check_status: 'saved')
  end

  private

    def publish_to_channel
      begin
        PusherClient.new("pos_checks_#{branch_id}").publish(
          "pos_check",
          {
            pos_check: ApplicationController.new.render_to_string(partial: "layouts/partner/kds_menu_item", locals: { pos_check: self }),
            check_id: id,
            kds_type: kds_type
          }
        )
      rescue => e
        
      end
    end
end
