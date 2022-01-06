class PusherClient
  PUSHER_CREDENTIALS = {
    "production" => { app_id: "561959", key: "e9be41db8225a0ad8e7f", secret: "d37ff685fc5feeb6bcb5" },
    "development" => { app_id: "910326", key: "c484e921b5dcec12b06e", secret: "2bcd3b146887a0933c98" }
  }

  attr_reader :channel

  def initialize(channel)
    @channel = channel
  end

  def publish(event, data = {})
    client.trigger(channel, event, data)
  end

  private

    def client
      @client = Pusher::Client.new(
        app_id: credentials[:app_id],
        key: credentials[:key],
        secret: credentials[:secret],
        cluster: "ap2",
        encrypted: true
      )
    end

    def credentials
      @credentials ||= PUSHER_CREDENTIALS[Rails.env]
    end
end
