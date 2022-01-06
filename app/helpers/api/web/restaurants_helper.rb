module Api::Web::RestaurantsHelper
  def web_restaurant_json(restaurants)
    restaurants.as_json(only: [:id, :title, :logo], include: [branch: { only: [:id, :address] }], methods: [:restaurant_avg_rating], logdinUser: @user)
  end

  def web_branch_json(branches)
    branches.as_json(only: [:id, :title, :logo], methods: [:restaurant_avg_rating], logdinUser: @user)
  end

  def get_all_restaurants(keyword, page, per_page)
    Branch.web_find_all_resturant(keyword, page, per_page)
  end
end
