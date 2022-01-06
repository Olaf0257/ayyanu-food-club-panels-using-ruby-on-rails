class BrandsController < ApplicationController
	helper_method :current_restaurant

	def current_restaurant
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
  end

  def filter_branch_by_country
    @country = Country.find_by(id: params[:country_id])
    @branches = current_restaurant.branches.where(country: @country.try(:name))
    @stores = current_restaurant.stores.where(country_ids: params[:country_id].split)
    @vendors = current_restaurant.vendors.where(country_id: @country.try(:id))
    @over_groups = current_restaurant.over_groups.where(country_ids: params[:country_id].split)
    @major_groups = current_restaurant.major_groups.where(country_ids: params[:country_id].split)
    @recipe_groups = current_restaurant.recipe_groups.where(country_ids: params[:country_id].split)
    @units = current_restaurant.units.where(country_ids: params[:country_id].split)
  end

  def filter_branches_by_country
  	@countries = Country.where(id: params[:country_ids])
    @branches = current_restaurant.branches.where(country: @countries.try(:pluck, :name))
    @taxes = Tax.where(country: @countries.try(:pluck, :id)) if params[:tax].present?
  end

  def filter_coverage_areas_by_country
    @country = Country.find_by(name: params[:country_name])
    @areas = get_coverage_area_web("", 1, 300).where(country_id: @country.id)
  end

  def filter_tax_by_country
    @country = Country.find_by(name: params[:country_name])
    @taxes = Tax.where(country: @country)
  end
end