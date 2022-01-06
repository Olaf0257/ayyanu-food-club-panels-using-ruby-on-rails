class ScrapMenuThroughTalabatWorker
  include Sidekiq::Worker
  include ApplicationHelper
  include Api::ApiHelper
  sidekiq_options retry: false

  def perform(html_content, restaurant)
    parser = Nokogiri::HTML(html_content, nil, Encoding::UTF_8.to_s)
    local_restaurant = get_restaurant(restaurant)
    branches = local_restaurant.branches

    if parser.css(".rest-logo-bg").present?
      parser.css(".rest-logo-bg").each do |rest|
        begin
          image = upload_multipart_image_scrap_menu(rest.at_css("img")["src"].split("?").first, "admin")
          image_url = image.presence || ""
        rescue Exception => e
        end

        local_restaurant.update(logo: image_url) if image_url.present?
      end
    end

    if parser.css(".menu-info").present?
      menu_items_id = []
      menu_category_id = []

      if branches.present?
        parser.css(".menu-info").each do |rest|
          rest.css(".panel").each do |new_data|
            category = branches.first.menu_categories.find_by(category_title: new_data.at_css("span").text)

            if category.present?
              category.update(category_title: new_data.at_css("span").text, categroy_title_ar: new_data.at_css("span").text)
              menu_category_id << category.id

              new_data.css(".panel-collapse").each do |menu|
                menu.css(".cat-items").each do |menu_item|
                  local_item = category.menu_items.find_by(item_name: menu_item.at_css("p").text)

                  if local_item.present?
                    menu_items_id << local_item.id

                    begin
                      image = upload_multipart_image_scrap_menu(menu_item.at_css("img")["src"].split("?").first, "menu_item") if local_item.item_image.blank?
                      image_url = image.presence || local_item.item_image
                    rescue Exception => e
                    end

                    local_item.update(item_name: menu_item.at_css("p").text, item_name_ar: menu_item.at_css("p").text, price_per_item: menu_item.at_css("span").text.split(" ").last.to_f, item_description: menu_item.at_css(".f-12").text, item_description_ar: menu_item.at_css(".f-12").text, item_image: image_url)
                  else
                    begin
                      image = upload_multipart_image_scrap_menu(menu_item.at_css("img")["src"].split("?").first, "menu_item") if menu_item.at_css("img")["src"].split("?").present?
                      image_url = image.presence || ""
                    rescue Exception => e
                    end

                    menuItem = category.menu_items.create(item_name: menu_item.at_css("p").text, item_name_ar: menu_item.at_css("p").text, price_per_item: menu_item.at_css("span").text.split(" ").last.to_f, item_description: menu_item.at_css(".f-12").text, item_description_ar: menu_item.at_css(".f-12").text, item_image: image_url)
                    menu_items_id << menuItem.id
                  end
                end
              end
            else
              menuCategory = branches.first.menu_categories.create(category_title: new_data.at_css("span").text, categroy_title_ar: new_data.at_css("span").text)

              new_data.css(".panel-collapse").each do |menu|
                menu.css(".cat-items").each do |menu_item|
                  next unless menuCategory
                  begin
                    menu_category_id << menuCategory.id
                    image = upload_multipart_image_scrap_menu(menu_item.at_css("img")["src"].split("?").first, "menu_item") if menu_item.at_css("img")["src"].split("?").present?
                    image_url = image.presence || ""
                    data = menuCategory.menu_items.create(item_name: menu_item.at_css("p").text, item_name_ar: menu_item.at_css("p").text, price_per_item: menu_item.at_css("span").text.split(" ").last.to_f, item_description: menu_item.at_css(".f-12").text, item_description_ar: menu_item.at_css(".f-12").text, item_image: image_url)
                    menu_items_id << data.id
                  rescue Exception => e
                  end
                end
              end
            end

            extra_menu_item = category.menu_items.where.not(id: menu_items_id) if category.present?
            extra_menu_item&.destroy_all
            menu_items_id.clear
          end
        end

        extra_menu_category = branches.first.menu_categories.where.not(id: menu_category_id)
        extra_menu_category&.destroy_all

        begin
          @webPusher = web_pusher(Rails.env)
          pusher_client = Pusher::Client.new(
            app_id: @webPusher[:app_id],
            key: @webPusher[:key],
            secret: @webPusher[:secret],
            cluster: "ap2",
            encrypted: true
          )
          pusher_client.trigger("my-channel", "my-event", {})
          Notification.create!(message: "#{local_restaurant.title} Menu Upload successfully!!", notification_type: "menu_upload", admin_id: 1, restaurant_id: local_restaurant.id)
        rescue Exception => e
        end
      end
    end
  end
end
