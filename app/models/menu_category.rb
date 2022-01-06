class MenuCategory < ApplicationRecord
  serialize :station_ids, Array
  belongs_to :branch
  has_many :menu_items, dependent: :destroy
  before_save :downcase_menu_category_stuff
  after_commit :update_menu_items_station

  scope :available, -> { where(available: true) }
  scope :unavailable, -> { where(available: false) }

  def as_json(options = {})
    @user = options[:user]
    @language = options[:language]
    super(options.merge(except: [:created_at, :hs_id, :updated_at, :branch_id, :category_title, :categroy_title_ar], methods: [:category_title, :dish_end_time]))
  end

  def stations
    Station.where(id: self.station_ids)
  end

  def category_title
    if @language == "arabic"
      self["categroy_title_ar"]
    else
      self["category_title"]
    end
  end

  def self.findMenuCategoryBranch(category_title, branch_id)
    find_by(category_title: category_title, branch_id: branch_id)
  end

  def self.findMenuCategoryIdBranch(category_id, branch_id)
    find_by(id: category_id, branch_id: branch_id)
  end

  def self.findMenuCategoryByBranch(branch_id)
    where(branch_id: branch_id)
  end

  def dish_end_time
    end_time.present? ? end_time.time.strftime("%I:%M %p") : ""
  end

  def self.newMenuCategory(category_title, category_title_ar, branch_id, approve, available)
    create(category_title: category_title, categroy_title_ar: category_title_ar, branch_id: branch_id, approve: approve, available: available)
  end

  def self.updateMenuCategory(category, category_title, category_title_ar, branch_id, category_priority, available)
    category.update(category_title: category_title, categroy_title_ar: category_title_ar, branch_id: branch_id, approve: false, category_priority: category_priority, is_rejected: false, available: available)
  end

  def fill_changed_fields(column_names)
    update(changed_column_name: column_names.reject { |i| i == "updated_at" }.join(", ")) if column_names.present?
  end

  private

  def downcase_menu_category_stuff
    self.category_title = category_title.downcase.titleize
  end

  def update_menu_items_station
    if station_ids.present? && menu_items.present?
      menu_items.update_all(station_ids: station_ids)
    end
  end
end
