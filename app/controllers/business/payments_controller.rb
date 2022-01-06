class Business::PaymentsController < ApplicationController
  before_action :authenticate_business
  require "uri"
  require "net/http"
  # sk_test_ez7caCg30hbQMGLXqoJNVl5B

  #   def business_payment_account
  #     url = URI("https://api.tap.company/v2/business")
  #     http = Net::HTTP.new(url.host, url.port)
  #     http.use_ssl = true
  #     http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  #     request = Net::HTTP::Post.new(url)
  #     request["authorization"] = 'Bearer sk_test_nAFytKqBrmIxHaP6sjQTu4ez'
  #     request["content-type"] = 'application/json'
  #     request.body = {
  #   "name": {
  #     "en": "Areesh",
  #     "ar": " تاپ للدفع"
  #   },
  #   "type": "corp",
  #   "entity": {
  #     "legal_name": {
  #       "en": "Areesh",
  #       "ar": "فلكس ويرزدفع"
  #     },
  #     "is_licensed": true,
  #     "license_number": "2134342SE",
  #     "not_for_profit": false,
  #     "country": "BH",
  #     "settlement_by": "Acquirer",
  #     "documents": [
  #       {
  #         "type": "Commercial Registration",
  #         "number": "1234567890",
  #         "issuing_country": "SA",
  #         "issuing_date": "2019-07-09",
  #         "expiry_date": "2021-07-09"
  #       },
  #       {
  #         "type": "Commercial license",
  #         "number": "1234567890",
  #         "issuing_country": "SA",
  #         "issuing_date": "2019-07-09",
  #         "expiry_date": "2021-07-09"
  #       },
  #       {
  #         "type": "Trademark Document",
  #         "number": "1234567890",
  #         "issuing_country": "SA",
  #         "issuing_date": "2019-07-09",
  #         "expiry_date": "2021-07-09"
  #       }
  #     ],
  #     "bank_account": {
  #       "iban": "INBNK00045545555555555555"
  #     }
  #   },
  #   "contact_person": {
  #     "name": {
  #       "title": "Mr",
  #       "first": "Muhammed",
  #       "middle": "L",
  #       "last": "Fazan"
  #     },
  #     "contact_info": {
  #       "primary": {
  #         "email": "manvendra.s@hexagondl.com",
  #         "phone": {
  #           "country_code": "965",
  #           "number": "900000"
  #         }
  #       }
  #     },
  #     "is_authorized": true,

  #   },
  #   "brands": [
  #     {
  #       "name": {
  #         "en": "Areesh",
  #         "ar": "فلكس ويرز ت"
  #       },
  #       "sector": [
  #         "Sec 1",
  #         "Sec 2"
  #       ],
  #       "website": "https://www.flexwares.company/",
  #       "social": [
  #         "https://twitter.com/flexwares",
  #         "https://www.linkedin.com/company/flexwares/"
  #       ],

  #       "content": {
  #         "tag_line": {
  #           "en": "Walk free",
  #           "ar": "المشي الحرتروني",
  #           "zh": "自由走"
  #         },
  #         "about": {
  #           "en": "The Flexwares is a shoe store company selling awsome and long lasting shoes. Come and check out our products online. ",
  #           "ar": "هذه هي شركة لبيع الأحذية تبيع أحذية رهيبة وطويلة الأمد. تعال وتحقق من منتجاتنا عبر الإنتر",
  #           "zh": "这是一家鞋店公司，销售长久耐用的鞋子。快来在线查看我们的产品。"
  #         }
  #       }
  #     }
  #   ],
  #   "post": {
  #     "url": "http://flexwares.company/post_url"
  #   },
  #   "metadata": {
  #     "mtd": "metadata"
  #   }
  # }.to_json
  #     response = http.request(request)
  #     puts response.read_body
  #   end

  def payment_card
    render layout: "partner_application"
  end

  def add_card
    redirect_to business_card_details_path
  end
end
