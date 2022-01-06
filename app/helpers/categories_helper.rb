module CategoriesHelper
  def get_all_categories(keyword, start_date, end_date)
    categories = Category.includes(branches: :restaurant)
    categories = categories.where(country_id: @admin.country_id) unless is_super_admin?(@admin)
    categories = categories.where("title like ?", "%#{keyword}%") if keyword.present?
    categories = categories.where("DATE(categories.created_at) >= ?", start_date.to_date) if start_date.present?
    categories = categories.where("DATE(categories.created_at) <= ?", end_date.to_date) if end_date.present?
    categories = categories.order(:title)
  end
end
