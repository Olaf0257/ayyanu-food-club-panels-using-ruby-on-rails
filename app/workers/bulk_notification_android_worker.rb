require "fcm"
class BulkNotificationAndroidWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(type, title, message, device_id)
    fcm = FCM.new("AAAAll9ZGRo:APA91bGKeRcsry2ftQdEvR2p8xz4sBffIPFa65A-ySp-TAfiEKA7C7mEkOirKCIoRR7GEBs3rdtbQNdQsOV-O_7USUXOaSh2jUc76mD___Lwk81w1y14ziTQqlkhny6-gtTgG48HUpeD") # (ENV["FIREBASE_ANDROID"])
    registration_ids = device_id
    p "-Bulk-----registration_ids--------------#{registration_ids}================"
    options = {
      notification: {
        body: message,
        title: title
      },
      data: {
        notification_type: type,
        body: message,
        title: title,
        time_to_live: 108,
        sound: "default",
        delay_while_idle: true,
        collapse_key: "updated_state"
      }
    }
    response = fcm.send(registration_ids, options)
    p "-Bulk-----response--------------#{response}================"
  end
end
