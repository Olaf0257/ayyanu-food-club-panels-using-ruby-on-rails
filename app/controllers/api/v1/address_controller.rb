class Api::V1::AddressController < Api::ApiController
  before_action :authenticate_guest_access, except: [:remove_address]
  before_action :validate_address, only: [:add_address, :update_address]

  def add_address
    address = user_address_add(@user, @guestToken, params[:address_type], params[:address_name], params[:fname], params[:lname], params[:area], params[:block], params[:street], params[:building], params[:floor], params[:apartment_number], params[:additional_direction], params[:country_code], params[:contact], params[:landline], params[:latitude], params[:longitude], params[:area_id])
    address[:code] == 200 ? responce_json(code: 200, message: "Address added successfully", address: address_json(address[:result])) : send_json_response((address[:result]).to_s, "invalid")
  end

  def update_address
    address = get_user_address(params[:address_id])
    if address
      updateAddress = update_user_address(address, params[:address_type], params[:address_name], params[:fname], params[:lname], params[:area], params[:block], params[:street], params[:building], params[:floor], params[:apartment_number], params[:additional_direction], params[:country_code], params[:contact], params[:landline], params[:latitude], params[:longitude])
      updateAddress[:code] == 200 ? responce_json(code: 200, message: "Address updated successfully", address: address) : send_json_response((address[:result]).to_s, "invalid")
    else
      responce_json(code: 422, errors: "Invalid address!!")
    end
  end

  def remove_address
    address = get_user_address(params[:address_id])
    if address
      address.destroy
      responce_json(code: 200, message: "Address remove successfully")
    else
      responce_json(code: 422, errors: "Invalid address!!")
    end
  end

  def address_list
    addresses = get_address_area_wise(@user, params[:area_id], params[:page], params[:per_page])
    responce_json(code: 200, address: address_json(addresses))
   rescue StandardError => e
     responce_json(code: 200, address: [], message: "Please add a address!")
   end

  def guest_user_address
    address = get_guest_user_address(@guestToken)
    responce_json(code: 200, message: "Address details.", address: address_json(address))
  end

  def update_contact_number
    address = get_user_address(params[:address_id])
    if address
      address.update(contact: params[:contact], country_code: params[:country_code], contact_verification: to_boolean(params[:contact_verification]))
      responce_json(code: 200, message: "Address updated successfully", address: address)
    else
      responce_json(code: 422, errors: "Invalid address!!")
    end
  end

  def get_address
    address = get_user_address(params[:address_id])
    if address
      responce_json(code: 200, message: "Address view successfully", address: address_json(address))
    else
      responce_json(code: 422, errors: "Invalid address!!")
    end
  end

  private

  def validate_address
    address_type = ["Office", "Villa", "Apartment", "مكتب. مقر. مركز", "فيلا", "شقة"]
    @type = address_type.include? params[:address_type]
    user_role = @use.present? ? @user.auths.first.role == "customer" : "customer"
    unless @type && user_role && params[:country_code] && params[:area_id].present? && params[:contact].present?
      responce_json(code: 422, message: (@type ? user_role ? "Required parameter messing!!" : "You can't add address" : "Invalid address type").to_s)
    end
  end
end
