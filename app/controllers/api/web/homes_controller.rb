class Api::Web::HomesController < Api::ApiController
  def home
    result = web_home_page_data(params[:area_id], params[:image_width], params[:banner_img_width], request.headers["language"])
    responce_json(code: 200, home_data: result)
  end

  def web_coverage_area
    coverageArea = get_coverage_area_web(params[:keyword], params[:page], params[:per_page])
    areas = coverageArea.as_json(language: request.headers["language"])
    responce_json(code: 200, coverage_areas: coverageArea.as_json(language: request.headers["language"]), total_pages: coverageArea.total_pages, coverage_area_count: coverageArea.count)
  end

  def enable_restaurant_list
    restaurants = get_enable_restaurant_list(params[:keyword], params[:page], params[:per_page])
    p restaurants.count
    responce_json(code: 200, restaurants: restaurants.as_json(only: [:id, :title]), total_pages: restaurants.total_pages, restaurants_count: restaurants.count)
   end

   def web_coverage_area_by_country
    coverageArea = CoverageArea.where(country_id: params[:country_id]).order(area: "ASC").paginate(page: params[:page], per_page: params[:per_page])
    responce_json(code: 200, coverage_areas: coverageArea.as_json(language: request.headers["language"]), total_pages: coverageArea.total_pages, coverage_area_count: coverageArea.count)
   end
end
