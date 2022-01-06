class ItemAddon < ApplicationRecord
  belongs_to :item_addon_category
  has_many :cart_item_addons, dependent: :destroy
  has_many :order_item_addons, dependent: :destroy
  before_save :downcase_item_addon_stuff
  has_many :pos_transactions, as: :itemable , dependent: :destroy

  attr_accessor :language

  scope :available, -> { where(available: true) }
  scope :unavailable, -> { where(available: false) }

  def as_json(options = {})
    @user = options[:logdinUser]
    @language = options[:language]
    super(options.merge(except: [:created_at, :updated_at, :item_addon_category_id, :addon_title, :addon_title_ar], methods: [:addon_title]))
  end

  def addon_title
    if @language == "arabic"
      self["addon_title_ar"]
    else
      self["addon_title"]
    end
  end

  def effective_price(discount)
    if discount > 0
      discount_amount = (addon_price.to_f * discount.to_i) / 100
      price = format("%0.03f", addon_price.to_f - discount_amount).to_f
    else
      price = addon_price
    end
  end

  def self.create_new_addon_item(category, item_name, price_per_item, item_name_ar, approve, available, include_in_pos, include_in_app, preparation_time = 15)
    create(addon_title: item_name, addon_price: price_per_item, item_addon_category_id: category.id, addon_title_ar: item_name_ar, approve: approve, available: available, include_in_pos: include_in_pos, include_in_app: include_in_app, preparation_time: preparation_time)
  end

  def fill_changed_fields(column_names)
    update(changed_column_name: column_names.reject { |i| i == "updated_at" }.join(", ")) if column_names.present?
  end

  private

  def downcase_item_addon_stuff
    self.addon_title = addon_title.downcase.titleize
  end
end
