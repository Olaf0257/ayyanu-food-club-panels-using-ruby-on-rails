class PaymentsController < ApplicationController
  require "uri"
  require "net/http"

  before_action :require_admin_logged_in, except: [:order_charge_customer, :place_order_online, :party_points_charge_customer]

  def branch_bank_details
    @branch = Branch.find(decode_token(params[:branch_id]))
    @bank_detail = @branch.branch_bank_detail
    render layout: "admin_application"
  end

  def new_bank_details
    @branch = Branch.find(decode_token(params[:branch_id]))
    render layout: "admin_application"
  end

  def add_bank_details
    url = URI("https://api.tap.company/v2/business")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(url)
    request["authorization"] = "Bearer #{Rails.application.secrets['tap_business_secret_key']}"
    request["content-type"] = "application/json"

    @branch = Branch.find(decode_token(params[:branch_id]))
    @bank_detail = BranchBankDetail.find_or_initialize_by(branch_id: @branch.id)
    @bank_detail.legal_name = params[:legal_name].to_s.squish
    @bank_detail.iban = params[:iban].to_s.squish
    @bank_detail.account_number = params[:account_number].to_s.squish
    @bank_detail.beneficiary_address = params[:beneficiary_address].to_s.squish
    @bank_detail.bank_address = params[:bank_address].to_s.squish
    @bank_detail.swift_code = params[:swift_code].to_s.squish
    @bank_detail.contact_title = params[:contact_person_title].to_s.squish
    @bank_detail.contact_first_name = params[:contact_person_first].to_s.squish
    @bank_detail.contact_middle_name = params[:contact_person_middle].to_s.squish
    @bank_detail.contact_last_name = params[:contact_person_last].to_s.squish
    @bank_detail.contact_email = params[:contact_person_email].to_s.squish
    country_code = params[:full_phone].to_s.gsub(params[:contact].to_s, '')
    country_code[0] = ""
    @bank_detail.contact_country_code = country_code
    @bank_detail.contact_mobile = params[:contact].to_s.squish
    @bank_detail.brand_name = params[:brand_name].to_s.squish
    @bank_detail.sector =  params[:sector].to_s.squish
    @bank_detail.commercial_license_number = params[:commercial_license_number].to_s.squish
    @bank_detail.commercial_license_issuing_country = params[:commercial_license_issuing_country]
    @bank_detail.commercial_license_issuing_date = params[:commercial_license_issuing_date]
    @bank_detail.commercial_license_expiry_date = params[:commercial_license_expiry_date]
    @bank_detail.civil_id_number = params[:civil_id_number].to_s.squish
    @bank_detail.civil_id_issuing_country = params[:civil_id_issuing_country]
    @bank_detail.civil_id_issuing_date = params[:civil_id_issuing_date]
    @bank_detail.civil_id_expiry_date = params[:civil_id_expiry_date]

    commercial_license_id = get_tap_file_id(params[:commercial_license], "Commercial License")
    civil_id = get_tap_file_id(params[:civil_id], "Civil ID")

    @bank_detail.commercial_license_file_id = commercial_license_id
    @bank_detail.civil_id_file_id = civil_id

    commercial_license_url = params[:commercial_license].present? ? upload_multipart_image(params[:commercial_license], "admin") : ""
    @bank_detail.commercial_license = commercial_license_url

    civil_id_url = params[:civil_id].present? ? upload_multipart_image(params[:civil_id], "admin") : ""
    @bank_detail.civil_id = civil_id_url
    @bank_detail.destination_id = "NA"
    restaurant_title = @branch.restaurant.title + " " + "(" + @branch.address.to_s + ")"

    if @bank_detail.save
      bank_data = {
        "name": {
          "en": restaurant_title.first(60)
        },
        "type": "corp",
        "entity": {
          "legal_name": {
            "en": @bank_detail.legal_name
          },
          "country": CountryStateSelect.countries_collection.select { |i| i.first == @branch.restaurant.country.name }.first.last.to_s,
          "documents": [
            {
              "type": "Commercial License",
              "number": @bank_detail.commercial_license_number,
              "issuing_country": CountryStateSelect.countries_collection.select { |i| i.first == @bank_detail.commercial_license_issuing_country }.first.last.to_s,
              "issuing_date": @bank_detail.commercial_license_issuing_date,
              "expiry_date": @bank_detail.commercial_license_expiry_date,
              "images": [
                @bank_detail.commercial_license_file_id
              ]
            },
            {
              "type": "CIVIL ID",
              "number": @bank_detail.civil_id_number,
              "issuing_country": CountryStateSelect.countries_collection.select { |i| i.first == @bank_detail.civil_id_issuing_country }.first.last.to_s,
              "issuing_date": @bank_detail.civil_id_issuing_date,
              "expiry_date": @bank_detail.civil_id_expiry_date,
              "images": [
                @bank_detail.civil_id_file_id
              ]
            }
          ],
          "bank_account": {
            "iban": @bank_detail.iban,
            "account_number": @bank_detail.account_number,
            "bank_address": @bank_detail.bank_address,
            "beneficiary_address": @bank_detail.beneficiary_address,
            "swift_code": @bank_detail.swift_code
          }
        },
        "contact_person": {
          "name": {
            "title": @bank_detail.contact_title,
            "first": @bank_detail.contact_first_name,
            "middle": @bank_detail.contact_middle_name,
            "last": @bank_detail.contact_last_name
          },
          "contact_info": {
            "primary": {
              "email": @bank_detail.contact_email,
              "phone": {
                "country_code": @bank_detail.contact_country_code,
                "number": @bank_detail.contact_mobile
              }
            }
          }
        },
        "brands": [
          {
            "name": {
              "en": @bank_detail.brand_name
            },
            "sector": [@bank_detail.sector],
            "website": "https://www.foodclubapp.com"
          }
        ]
      }

      request.body = bank_data.to_json
      response = http.request(request)
      data = JSON.parse(response.read_body)

      if data["destination_id"].present?
        @bank_detail.update(destination_id: data["destination_id"])
        flash[:success] = "Bank Detail Successfully Added!"
      else
        @errors = data["errors"].map { |i| i["description"].present? ? i["description"] : i["message"] }.join(", ")
        @bank_detail.destroy
      end
    else
      @errors = @bank_detail.errors.full_messages.join(", ")
    end
  end

  def influencer_bank_details
    @user = User.find(decode_token(params[:user_id]))
    @bank_detail = @user.influencer_bank_detail
    render layout: "admin_application"
  end

  def new_influencer_bank_details
    @user = User.find(decode_token(params[:user_id]))
    render layout: "admin_application"
  end

  def add_influencer_bank_details
    url = URI("https://api.tap.company/v2/business")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(url)
    request["authorization"] = "Bearer #{Rails.application.secrets['tap_business_secret_key']}"
    request["content-type"] = "application/json"

    @user = User.find(decode_token(params[:user_id]))
    @bank_detail = InfluencerBankDetail.find_or_initialize_by(user_id: @user.id)
    @bank_detail.legal_name = params[:legal_name].to_s.squish
    @bank_detail.iban = params[:iban].to_s.squish
    @bank_detail.account_number = params[:account_number].to_s.squish
    @bank_detail.beneficiary_address = params[:beneficiary_address].to_s.squish
    @bank_detail.bank_address = params[:bank_address].to_s.squish
    @bank_detail.swift_code = params[:swift_code].to_s.squish
    @bank_detail.contact_title = params[:contact_person_title].to_s.squish
    @bank_detail.contact_first_name = params[:contact_person_first].to_s.squish
    @bank_detail.contact_middle_name = params[:contact_person_middle].to_s.squish
    @bank_detail.contact_last_name = params[:contact_person_last].to_s.squish
    @bank_detail.contact_email = params[:contact_person_email].to_s.squish
    country_code = params[:full_phone].to_s.gsub(params[:contact].to_s, '')
    country_code[0] = ""
    @bank_detail.contact_country_code = country_code
    @bank_detail.contact_mobile = params[:contact].to_s.squish
    @bank_detail.brand_name = params[:brand_name].to_s.squish
    @bank_detail.sector =  params[:sector].to_s.squish
    @bank_detail.civil_id_number = params[:civil_id_number].to_s.squish
    @bank_detail.civil_id_issuing_country = params[:civil_id_issuing_country]
    @bank_detail.civil_id_issuing_date = params[:civil_id_issuing_date]
    @bank_detail.civil_id_expiry_date = params[:civil_id_expiry_date]

    civil_id = get_tap_file_id(params[:civil_id], "Civil ID")
    @bank_detail.civil_id_file_id = civil_id
    civil_id_url = params[:civil_id].present? ? upload_multipart_image(params[:civil_id], "admin") : ""
    @bank_detail.civil_id = civil_id_url
    @bank_detail.destination_id = "NA"
    user_title = @user.name + " " + "(" + @user.email.to_s + ")"

    if @bank_detail.save
      bank_data = {
        "name": {
          "en": user_title.first(60)
        },
        "type": "corp",
        "entity": {
          "legal_name": {
            "en": @bank_detail.legal_name
          },
          "country": CountryStateSelect.countries_collection.select { |i| i.first == @user.country.name }.first.last.to_s,
          "documents": [
            {
              "type": "CIVIL ID",
              "number": @bank_detail.civil_id_number,
              "issuing_country": CountryStateSelect.countries_collection.select { |i| i.first == @bank_detail.civil_id_issuing_country }.first.last.to_s,
              "issuing_date": @bank_detail.civil_id_issuing_date,
              "expiry_date": @bank_detail.civil_id_expiry_date,
              "images": [
                @bank_detail.civil_id_file_id
              ]
            }
          ],
          "bank_account": {
            "iban": @bank_detail.iban,
            "account_number": @bank_detail.account_number,
            "bank_address": @bank_detail.bank_address,
            "beneficiary_address": @bank_detail.beneficiary_address,
            "swift_code": @bank_detail.swift_code
          }
        },
        "contact_person": {
          "name": {
            "title": @bank_detail.contact_title,
            "first": @bank_detail.contact_first_name,
            "middle": @bank_detail.contact_middle_name,
            "last": @bank_detail.contact_last_name
          },
          "contact_info": {
            "primary": {
              "email": @bank_detail.contact_email,
              "phone": {
                "country_code": @bank_detail.contact_country_code,
                "number": @bank_detail.contact_mobile
              }
            }
          }
        },
        "brands": [
          {
            "name": {
              "en": @bank_detail.brand_name
            },
            "sector": [@bank_detail.sector],
            "website": "https://www.foodclubapp.com"
          }
        ]
      }

      request.body = bank_data.to_json
      response = http.request(request)
      data = JSON.parse(response.read_body)

      if data["destination_id"].present?
        @bank_detail.update(destination_id: data["destination_id"])
        flash[:success] = "Bank Detail Successfully Added!"
      else
        @errors = data["errors"].map { |i| i["description"].present? ? i["description"] : i["message"] }.join(", ")
        @bank_detail.destroy
      end
    else
      @errors = @bank_detail.errors.full_messages.join(", ")
    end
  end

  def order_charge_customer
    @order_mode = params[:order_mode]
    @user_id = params[:user_id]
    @address_id = params[:address_id]
    @redeem = params[:is_redeem]
    @note = params[:note]
    @coupon_code = params[:coupon_code]
    @amount = params[:amount].to_f.round(3)
    @token_id = params[:token_id]
    @guest_token = params[:guest_token]
    @user = User.find(@user_id)
    @cart = @user.cart
    @branch = @user.cart.branch

    url = URI("https://api.tap.company/v2/charges")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(url)
    request["authorization"] = "Bearer #{Rails.application.secrets['tap_secret_key']}"
    request["content-type"] = "application/json"

    card_data = {
      "amount": @amount,
      "currency": @branch.currency_code_en,
      "description": "Food Club Order",
      "receipt": {
        "email": true,
        "sms": true
      },
      "customer": {
        "first_name": @user.name,
        "email": @user.email,
        "phone": {
          "country_code": @user.country_id.present? ? Country::PHONE_CODES[@user.country_id] : Country::PHONE_CODES[@branch.restaurant.country_id],
          "number": @user.contact
        }
      },
      "source": {
        "id": @token_id
      },
      "redirect": {
        "url": place_order_online_url(order_mode: @order_mode, user_id: @user_id, address_id: @address_id, is_redeem: @redeem, note: @note, coupon_code: @coupon_code, guest_token: @guest_token)
      }
    }

    request.body = card_data.to_json
    response = http.request(request)
    @data = JSON.parse(response.read_body)

    if @data["transaction"] && @data["transaction"]["url"]
      @payment_url = @data["transaction"]["url"]
    else
      flash[:error] = @data["errors"].map{ |i| i["description"] }.join(", ")
      redirect_to request.referer
    end
  end

  def party_points_charge_customer
    @seller_id = params[:seller_id]
    @buyer_id = params[:buyer_id]
    @restaurant_id = params[:restaurant_id]
    @amount = params[:selling_price].to_f
    @available_points = params[:available_points]
    @token_id = params[:token_id]
    @seller = User.find(@seller_id)
    @buyer = User.find(@buyer_id)

    url = URI("https://api.tap.company/v2/charges")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(url)
    request["authorization"] = "Bearer #{Rails.application.secrets['tap_secret_key']}"
    request["content-type"] = "application/json"

    card_data = {
      "amount": @amount,
      "currency": @seller.country.currency_code,
      "description": "Buy Food Club Party Points",
      "receipt": {
        "email": true,
        "sms": true
      },
      "customer": {
        "first_name": @buyer.name,
        "email": @buyer.email,
        "phone": {
          "country_code": Country::PHONE_CODES[@seller.country_id],
          "number": @buyer.contact
        }
      },
      "source": {
        "id": @token_id
      },
      "redirect": {
        "url": customer_buy_party_points_url(buyer_id: @buyer_id, seller_id: @seller_id, restaurant_id: @restaurant_id, selling_price: @amount, available_points: @available_points)
      }
    }

    request.body = card_data.to_json
    response = http.request(request)
    @data = JSON.parse(response.read_body)

    if @data["transaction"] && @data["transaction"]["url"]
      @payment_url = @data["transaction"]["url"]
    else
      flash[:error] = @data["errors"].map{ |i| i["description"] }.join(", ")
      redirect_to request.referer
    end
  end

  def place_order_online
    @order_mode = params[:order_mode]
    @user_id = params[:user_id]
    @address_id = params[:address_id]
    @redeem = params[:is_redeem]
    @note = params[:note]
    @coupon_code = params[:coupon_code]
    @charge_id = params[:tap_id]
    @guest_token = params[:guest_token]

    url = URI("https://api.tap.company/v2/charges/#{@charge_id}")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(url)
    request["authorization"] = "Bearer #{Rails.application.secrets['tap_secret_key']}"
    request.body = "{}"

    response = http.request(request)
    data = JSON.parse(response.read_body)

    if data["status"] != "CAPTURED"
      flash[:error] = "TRANSACTION " + data["status"].to_s
      redirect_to customer_cart_item_list_path(user_id: @user_id, address_id: @address_id, my_points: @redeem, note: @note, coupon_code: @coupon_code, guest_token: @guest_token)
    end
  end

  private

  def get_tap_file_id(document, title)
    request = `curl --location --request POST "https://api.tap.company/v2/files" \
    --header "Authorization: Bearer #{Rails.application.secrets['tap_business_secret_key']}" \
    --form "file=@#{File.expand_path(document.path)}" \
    --form "purpose=identity_document" \
    --form "title=#{title}" \
    --form "file_link_create=true"`

    JSON.parse(request)["id"]
  rescue Exception => e
  end
end