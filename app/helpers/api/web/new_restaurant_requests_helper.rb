module Api::Web::NewRestaurantRequestsHelper
  require "dropbox"
  def add_restaurant_request(restaurant_name, restaurant_id, person_name, contact_number, role, email, area, cuisine, cr_number, bank_name, bank_account, _images, _signature, cpr_number, owner_name, nationality, submitted_by, delivery_status, branch_no, mother_company_name, serving, block, road_number, building, unit_number, floor, other_name, other_role, other_email,country_id)
    restaurant = NewRestaurant.create_restaurant_request_details(restaurant_name, restaurant_id, person_name, contact_number, role, email, area, cuisine, cr_number, bank_name, bank_account, cpr_number, owner_name, nationality, submitted_by, delivery_status, branch_no, mother_company_name, serving, block, road_number, building, unit_number, floor, other_name, other_role, other_email, country_id)
    begin
      if restaurant.id.present? && params[:images].present?
        app_key = "gf3h7ccuo7pvhm3"
        app_secret = "ab35tygk5uz1xnx"
        dbx = Dropbox::Client.new("4wymnERGF4AAAAAAAAAAGn94L0ztu96ZTjBmlc9sHl9kvzfqG98YaHBWCjLUOBvQ")
        file = open(params[:images])
        file_name = params[:images].original_filename
        file = dbx.upload("/#{Time.now.to_i}#{file_name}", file)
        result = HTTParty.post("https://api.dropboxapi.com/2/sharing/create_shared_link",
                               body: { path: file.path_display }.to_json,
                               headers: { "Authorization" => "Bearer 4wymnERGF4AAAAAAAAAAGn94L0ztu96ZTjBmlc9sHl9kvzfqG98YaHBWCjLUOBvQ", "Content-Type" => "application/json" })
        NewRestaurantImage.create(url: result.parsed_response["url"], new_restaurant_id: restaurant.id, doc_type: "Cr  Document")
        upload_signature_on_dropbox(restaurant)
       end
    rescue Exception => e
    end
    restaurant
  end

  def upload_signature_on_dropbox(restaurant)
    app_key =  "gf3h7ccuo7pvhm3"
    app_secret = "ab35tygk5uz1xnx"
    dbx = Dropbox::Client.new("4wymnERGF4AAAAAAAAAAGn94L0ztu96ZTjBmlc9sHl9kvzfqG98YaHBWCjLUOBvQ")
    file = open(params[:signature])
    file_name = params[:signature].original_filename
    file = dbx.upload("/#{Time.now.to_i}#{file_name}", file)
    result = HTTParty.post("https://api.dropboxapi.com/2/sharing/create_shared_link",
                           body: { path: file.path_display }.to_json,
                           headers: { "Authorization" => "Bearer 4wymnERGF4AAAAAAAAAAGn94L0ztu96ZTjBmlc9sHl9kvzfqG98YaHBWCjLUOBvQ", "Content-Type" => "application/json" })
    NewRestaurantImage.create(url: result.parsed_response["url"], new_restaurant_id: restaurant.id, doc_type: "Signature")
    rescue Exception => e
  end
end
