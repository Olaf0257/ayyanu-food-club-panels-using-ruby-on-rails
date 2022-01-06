class Api::V1::CountriesController < Api::ApiController
  def list
    @countries = if params[:all_country].present?
                   Country.all.as_json
                 else
                   Country.where(id: CoverageArea.active_areas.pluck(:country_id).uniq).as_json
                 end

    responce_json(code: 200, countries: @countries)
  end
end
