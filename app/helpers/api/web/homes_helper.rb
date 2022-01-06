module Api::Web::HomesHelper
  def web_home_page_data(area_id, image_width, banner_img_width, language)
    page = 1
    per_page = 10
    restaurants_branch = get_restaurants(page, per_page, area_id) # branch data area wise
    categories = get_category(page, per_page, area_id)
    advertisements = get_advertisement(page, per_page)
    { categories_count: categories.count, categories_total_page: categories.total_pages, restaurant_count: restaurants_branch.count, restaurant_total_page: restaurants_branch.total_pages, categories: home_json(categories, "", language), restaurants: restaurants_branch.as_json(only: [:id, :title, :logo], include: [branch: { only: [:id, :address] }], methods: [:restaurant_avg_rating], imgWidth: image_width, language: language), advertisements: advertisements.as_json(imgWidth: banner_img_width) }
  end
end
