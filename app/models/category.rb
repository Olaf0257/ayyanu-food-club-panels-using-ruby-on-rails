class Category < ApplicationRecord
  has_many :branch_categories, dependent: :destroy
  has_many :branches, through: :branch_categories
  belongs_to :country, optional: true

  scope :order_by_title, -> { order("`title` = 'Party' desc, title ASC") }

  def as_json(options = {})
    @user = options[:logdinUser]
    @language = options[:language]
    super(options.merge(except: [:created_at, :updated_at, :title, :title_ar], methods: [:title]))
  end

  def title
    if @language == "arabic"
      self["title_ar"]
    else
      self["title"]
      end
  end

  def self.find_category(_page, _per_page)
    Category.order_by_title.paginate(page: 1, per_page: 10)
  end

  def self.find_all_category(page, per_page)
    Category.order_by_title.paginate(page: page, per_page: per_page)
  end

  def self.create_category(title, url)
    create(title: title, icon: url)
  end

  def self.update_category_details(category, title, uploadImage, color)
    category.update(title: title.presence || category.title, icon: uploadImage, color: color.presence || category.color)
  end

  def self.category_list_csv
    CSV.generate do |csv|
      header = "Cuisine List"
      csv << [header]

      second_row = ["S.No.", "Name", "Restaurants", "Added On"]
      csv << second_row

      all.each_with_index do |category, i|
        @row = []
        @row << (i+1)
        @row << category.title
        @row << category.branches.pluck(:restaurant_id).uniq.size.to_s + " Restaurants"
        @row << category.created_at.strftime("%d/%m/%Y")
        csv << @row
      end
    end
  end
end
