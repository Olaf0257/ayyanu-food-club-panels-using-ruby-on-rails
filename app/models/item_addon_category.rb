class ItemAddonCategory < ApplicationRecord
  belongs_to :branch, optional: true

  has_many :item_addons, dependent: :destroy
  has_many :menu_item_addon_categories, dependent: :destroy
  has_many :menu_items, through: :menu_item_addon_categories, source: :menu_item

  before_save :downcase_item_addon_category_stuff

  scope :available, -> { where(available: true) }
  scope :unavailable, -> { where(available: false) }

  def as_json(options = {})
    @user = options[:logdinUser]
    @language = options[:language]
    @menu_item_id = options[:item]
    super(options.merge(except: [:created_at, :updated_at, :addon_category_name, :addon_category_name_ar, :menu_item_id], methods: [:addon_category_name, :menu_item_id]))
  end

  def addon_category_name
    if @language == "arabic"
      self["addon_category_name_ar"]
    else
      self["addon_category_name"]
    end
  end

  def menu_item_id
    @menu_item_id.id
  end

  def self.create_new_addon_category(branch, addon_category_name, addon_category_name_ar, min_selected_quantity, max_selected_quantity, approve, available)
    create(branch_id: branch.id, addon_category_name: addon_category_name, addon_category_name_ar: addon_category_name_ar, min_selected_quantity: min_selected_quantity, max_selected_quantity: max_selected_quantity, approve: approve, available: available)
  end

  def fill_changed_fields(column_names)
    update(changed_column_name: column_names.reject { |i| i == "updated_at" }.join(", ")) if column_names.present?
  end

  private

  def downcase_item_addon_category_stuff
    self.addon_category_name = addon_category_name.downcase.titleize
  end
end
