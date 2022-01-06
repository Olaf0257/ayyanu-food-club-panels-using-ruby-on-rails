require "fcm"
class OrderIosPushWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(type, title, message, device_id, order_id)
    fcm = FCM.new("AAAAll9ZGRo:APA91bGKeRcsry2ftQdEvR2p8xz4sBffIPFa65A-ySp-TAfiEKA7C7mEkOirKCIoRR7GEBs3rdtbQNdQsOV-O_7USUXOaSh2jUc76mD___Lwk81w1y14ziTQqlkhny6-gtTgG48HUpeD") # (ENV["FIREBASE_IOS"])
    registration_ids = [device_id]
    p "---Bulk-----registration_ids--------------#{registration_ids}================"
    options = {
      notification: {
        body: message,
        title: title,
        sound: "notification.caf"
      },
      data: {
        notification_type: type,
        order_id: order_id,
        time_to_live: 108,
        delay_while_idle: true,
        collapse_key: "updated_state"
      }
    }
    response = fcm.send(registration_ids, options)
    p "---OrderIosPushWorker--------------#{response}=============="
  end
end
