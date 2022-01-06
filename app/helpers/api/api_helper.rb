module Api::ApiHelper
  include Api::V1::UsersHelper
  include Api::V1::HomesHelper
  include Api::V1::RestaurantsHelper
  include Api::V1::AddressHelper
  include Api::V1::CartsHelper
  include Api::V1::RegistrationsHelper
  include Api::V1::OrdersHelper
  include Api::Web::HomesHelper
  include Api::Web::RestaurantsHelper
  include Api::V1::TransportersHelper
  include Api::V1::PointsHelper
  include Business::UsersHelper
  include Api::V1::BusinessHelper
  include Api::V1::RatingsHelper
  include Api::V1::NotificationsHelper
  include Api::V1::GuestSessionsHelper
  include Api::V1::OffersHelper
  include Api::Web::CartsHelper
  include Api::V1::ClubesHelper
  include Api::Web::UsersHelper
  include Api::Web::NewRestaurantRequestsHelper
  include Api::V1::OrderReviewsHelper
  include Api::Web::OrdersHelper
  include Api::V1::ReferralsHelper

  def responce_json(resultJson)
    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { render json: resultJson }
    end
  end

  def model_errors(modelName)
    fullerror = []
    modelName.errors.map { |k, v| fullerror << "#{k} #{v}" }
    fullerror.join(", ")
  end

  def send_json_response(entity, message, resultjson)
    finaljsontosend = { code: response_code(message), message: response_message(message, entity) }
    respond_to do |format|
      format.json { render json: finaljsontosend.merge(resultjson) }
    end
  end

  def json_response(jsonobj)
    respond_to do |format|
      format.json { render json: jsonobj }
    end
  end

  def response_code(msg)
    case msg
    when "success"
      success_codes[0]
    when "created"
      success_codes[1]
    when "accepted"
      success_codes[2]
    when "updated"
      success_codes[3]
    when "blank"
      error_codes[0]
    when "exists"
      error_codes[1]
    when "not exists"
      error_codes[3]
    when "unauthorized"
      error_codes[4]
    when "unapproved"
      error_codes[5]
    when "invalid"
      error_codes[7]
    when "bad"
      error_codes[2]
    else
      error_codes[6]
    end
  end

  def success_codes
    [200, 201, 202, 205]
  end

  def error_codes
    [204, 208, 400, 404, 401, 403, 1000, 420]
  end

  def response_message(msg, entity)
    case msg
    when "blank"
      "#{entity} does not have any content !!"
    when "exists"
      "#{entity} already exists !!"
    when "not exists"
      "#{entity} does not exists !!"
    when "unauthorized"
      "Unauthorized access !! #{entity}"
    when "unapproved"
      entity.to_s
    when "bad"
      "Bad Request, #{entity}"
    when "suspend"
      "#{entity} suspend !!"
    else
      entity.to_s
    end
  end

  def upload_multipart_image_scrap_menu(image, folder_name)
    imagekitio = ImageKit::ImageKitClient.new(Rails.application.secrets['imagekit_private_key'], Rails.application.secrets['imagekit_public_key'], Rails.application.secrets['imagekit_url_endpoint'])
    image = imagekitio.upload_file(image, "foodclub_menu_item_image", folder: folder_name)
    image[:response]["url"]
    rescue Exception => e
  end

  def upload_multipart_image(image, folder_name, original_filename=nil)
    original_filename = original_filename || image.original_filename
    imagekitio = ImageKit::ImageKitClient.new(Rails.application.secrets['imagekit_private_key'], Rails.application.secrets['imagekit_public_key'], Rails.application.secrets['imagekit_url_endpoint'])
    image = imagekitio.upload_file(image, original_filename, folder: folder_name)
    image[:response]["url"]
    rescue Exception => e
  end

  def update_multipart_image(prev_image_name, new_image, folder_name)
    remove_multipart_image(prev_image_name, folder_name) if prev_image_name.present?
    upload_multipart_image(new_image, folder_name)
  end

  def remove_multipart_image(image_name, folder_name)
    imagekitio = ImageKit::ImageKitClient.new(Rails.application.secrets['imagekit_private_key'], Rails.application.secrets['imagekit_public_key'], Rails.application.secrets['imagekit_url_endpoint'])
    file = imagekitio.list_files({ name: image_name })[:response].first
    delete = imagekitio.delete_file(file["fileId"]) if file && file["fileId"].present?
    rescue Exception => e
  end

  def order_accept_worker(order_id)
    EmailOnOrderAccept.perform_async(order_id)
    rescue Exception => e
  end

  def order_reject_worker(order_id)
    EmailOnOrderReject.perform_async(order_id)
    rescue Exception => e
  end

  def order_cancel_worker(order_id)
    EmailOnOrderCancel.perform_async(order_id)
    rescue Exception => e
  end

  def orderPushNotificationWorker(sender, receiver, type, title, message, order_id)
    device = receiver.auths.first.server_sessions.last.session_device

    if receiver && receiver.auths.first.role != "transporter"
      @receiver_ids = []

      if order_id
        @branch_id = Order.find(order_id).branch_id
        @receiver_ids << receiver.id
        @receiver_ids << Order.find(order_id).branch.restaurant.user.id if type == "order_cancelled"
        @receiver_ids << BranchManager.where(branch_id: @branch_id).pluck(:user_id)
        @receiver_ids << BranchKitchenManager.where(branch_id: @branch_id).pluck(:user_id)
      end

      @receiver_ids.flatten.each do |receiver_id|
        noti = Notification.create(notification_type: type, message: message, user_id: sender.id, receiver_id: receiver_id, order_id: order_id)
      end
    end

    if device.device_type == "ios"
      OrderIosPushWorker.perform_async(type, title, message, device.device_id, order_id)
    else
      OrderAndroidPushWorker.perform_async(type, title, message, device.device_id, order_id)
    end
  rescue StandardError => e
  end

  def offerPushNotificationWorker(sender, receiver, type, title, message, id)
    device = receiver.auths.first.server_sessions.last.session_device
    noti = Notification.create(notification_type: type, message: message, admin_id: sender.id, receiver_id: receiver.id)
    if device.device_type == "ios"
      OfferIosPushWorker.perform_async(type, title, message, device.device_id, id)
    else
      OfferAndroidPushWorker.perform_async(type, title, message, device.device_id, id)
    end
  rescue StandardError => e
  end

  def store_redirect(apptype)
    app = AppDetail.where(app_type: "customer").first
    nextPath = if apptype == "android"
                 app ? app.android_store_link : ""
               # nextPath = ""
               elsif apptype == "ios"
                 app ? app.ios_store_link : ""
               # nextPath = "https://itunes.apple.com/us/app/gpdock/id1347118363?mt=8"
               else
                 root_url
               end
    nextPath
  end
end
