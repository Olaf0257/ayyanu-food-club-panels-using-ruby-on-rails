Rails.application.routes.draw do
  devise_for :auths
  root to: "welcome#index"
  get "auth/google_oauth2/callback", to: "sessions#google_auth"
  get "auth/facebook/callback", to: "sessions#facebook_auth"
  get "auth/instagram/callback", to: "sessions#instagram_auth"
  get "auth/failure", to: redirect("/")

  resources :job_openings

  require "sidekiq/web"
  require 'sidekiq-scheduler/web'
  mount Sidekiq::Web => "/sidekiq"
  # mount Ckeditor::Engine => '/ckeditor'
  # ======================Admin path=============================
  # root to: 'super_admins#index'

  resources :distance_delivery_charges do
    post :update_charge, on: :collection
    post :update_fixed_charge, on: :collection
    post :new_fixed_charge, on: :collection
  end

  resources :delivery_companies do
    get :requested_list, on: :collection
    get :rejected_list, on: :collection
    get :approve, on: :member
    get :reject, on: :member
    get :activate, on: :member
    get :deactivate, on: :member
    get :driver_locations, on: :member
    get :state_list, on: :collection
    get :district_list, on: :collection
    get :zone_list, on: :collection
    get :settle_amount_list, on: :member
    post :settle_amount, on: :collection
    get :login_as_company, on: :member
  end

  resources :posts do
    get :list, on: :collection
  end

  resources :post_categories
  resources :branch_subscriptions
  resources :report_subscriptions
  resources :admin_offers

  resources :zones do
    get :free_area_list, on: :member
    post :add_area_to_zone, on: :collection
    get :remove_area_from_zone, on: :collection
  end

  resources :districts do
    get :state_list, on: :collection
  end

  resources :influencer_coupons do
    get :activate, on: :member
    get :branch_list, on: :collection
    get :category_list, on: :collection
    get :item_list, on: :collection
    get :add_new_row, on: :collection
    get :user_list, on: :member
    get :view_notes, on: :member
  end

  resources :referral_coupons do
    get :activate, on: :member
    get :branch_list, on: :collection
    get :category_list, on: :collection
    get :item_list, on: :collection
    get :add_new_row, on: :collection
    get :user_list, on: :member
    get :view_notes, on: :member
  end

  resources :restaurant_coupons do
    get :activate, on: :member
    get :branch_list, on: :collection
    get :category_list, on: :collection
    get :item_list, on: :collection
    get :add_new_row, on: :collection
    get :user_list, on: :member
    get :view_notes, on: :member
  end

  resources :taxes

  resources :events do
    get :event_date_list, on: :member
    get :event_calendar, on: :collection
    get :add_event_date, on: :collection
    get :edit_event_date, on: :collection
    get :remove_event_date, on: :collection
  end


  resources :enterprises do 
    collection do
      get 'requested_enterprise'
      get 'enterprise_view'
      # get 'edit_request_enterprise'
    end
    member do
      get 'enterprise_request_details'
    end
  end
  get "edit/request/enterprise/:id" => "enterprises#edit_request_enterprise", as: "edit_request_enterprise"
  post "update/request/enterprise" => "enterprises#update_request_enterprise"
  get "/business/find_branches_based_country" => "business/partners#find_branches_based_country"
  post "/business/set_branch" => "business/partners#set_branch"



  post "/approved/enterprises" => "enterprises#approve_enterprise"
  post "/reject/enterprise" => "enterprises#reject_enterprise_request"
  get "enterprise/list" => "enterprises#all_enterprise"
  get "enterprise/remove" => "restaurants#remove_restaurant"
  get "rejected/enterprise" => "enterprises#rejected_enterprise"
  get "delete/enterprise/:id" => "enterprises#delete_enterprise"

  get "enterprise/information" => "enterprises#information"
  get "enterprise/request" => "enterprises#new_restaurant_request"
  get "enterprise/get_states" => "enterprises#get_states"
  get "influencer/list" => "influencers#list"
  get "influencer/rejected_list" => "influencers#rejected_list"
  get "influencer/requested_list" => "influencers#requested_list"
  get "influencer/new" => "influencers#new"
  post "influencer/create" => "influencers#create"
  get "influencer/edit" => "influencers#edit"
  post "influencer/update" => "influencers#update"
  get "influencer/approve" => "influencers#approve"
  get "influencer/reject" => "influencers#reject"
  get "influencer/remove" => "influencers#remove"
  get "influencer/:id/contracts" => "influencers#contracts", as: "influencer_contracts"
  post "influencer/add_contract" => "influencers#add_contract"
  post "influencer/update_contract" => "influencers#update_contract"
  post "influencer/remove_contract" => "influencers#remove_contract"

  get "influencer_bank_details" => "payments#influencer_bank_details"
  get "new_influencer_bank_details" => "payments#new_influencer_bank_details"
  post "add_influencer_bank_details" => "payments#add_influencer_bank_details"

  get "branch_bank_details" => "payments#branch_bank_details"
  get "new_bank_details" => "payments#new_bank_details"
  post "add_bank_details" => "payments#add_bank_details"
  get "order_charge_customer" => "payments#order_charge_customer"
  get "place_order_online" => "payments#place_order_online"
  get "branch_qr_code" => "restaurants#branch_qr_code"
  get "party_points_charge_customer" => "payments#party_points_charge_customer"

  get  "referral/:referral_code" => "welcome#referral", as: "referral"
  post "mapping/data" => "welcome#mapping_scrape_data", as: "mapping_scrape_data"
  post "submit_referral" => "welcome#submit_referral", as: "submit_referral"
  get "admin/login" => "super_admins#login", as: "admin_login"
  post "admin/auth" => "super_admins#admin_auth", as: "admin_auth"
  get "admin/dashboard" => "super_admins#dashboard", as: "dashboard"
  get "admin/logout" => "super_admins#admin_logout", as: "admin_logout"
  get "admin/upload/data/csv" => "super_admins#uploadDataCsv", as: "admin_csv"

  # =========================User routes===========================
  get "user/list" => "users#list"
  get "user/mark_influencer" => "users#mark_influencer"
  get "user/role_user_list" => "users#role_user_list"
  get "user/add_role_user" => "users#add_role_user"
  post "add_role_user" => "users#create_role_user"
  get "edit_role_user_password" => "users#edit_role_user_password"
  post "change_role_user_password" => "users#change_role_user_password"
  get "user/edit_role_user/:id" => "users#edit_role_user", as: "edit_role_user"
  patch "user/update_role_user/:id" => "users#update_role_user", as: "update_role_user"
  get "all/users" => "users#all_users"
  get "user/delete_role_user" => "users#delete_role_user", as: "delete_role_user"
  get "user/unapproved_user_list" => "users#unapproved_user_list"
  get "user/approve_role_user/:id" => "users#approve_role_user", as: "approve_role_user"
  get "user/reject_role_user/:id" => "users#reject_role_user", as: "reject_role_user"
  put "user/approve_role_user_multiple" => "users#approve_role_user_multiple"
  patch "user/update_role_user_reject/:id" => "users#update_role_user_reject", as: "update_role_user_reject"
  get "log_off_transporter" => "users#log_off_transporter", as: "log_off_transporter"
  get "user/address_list" => "users#address_list"
  get "user/point_list" => "users#point_list"
  get "user/point_details" => "users#point_details"
  get "user/edit_address" => "users#edit_address"
  patch "user/update_address" => "users#update_address"
  get "user/delete_address" => "users#delete_address"

  get "delivery_company/get_currency" => "users#get_currency", as: "get_currency"

  get "edit_delivery_company_password" => "delivery_companies#edit_delivery_company_password"
  post "change_delivery_company_password" => "delivery_companies#change_delivery_company_password"

  get "profile/:id" => "users#profile", as: "profile"
  # ======================remove_menu_addon_categorySuperAdmin routes============================================
  get "admin/upload/logo/json" => "super_admins#uploadLogoJson"
  get "admin/upload/item/img/json" => "super_admins#uploadItemImageJson"
  get "admin/upload/fast/img" => "super_admins#uploadFastImg"
  get "dashboard" => "super_admins#dashboard"
  get "admin/edit_password" => "super_admins#edit_password"
  post "admin/reset_password" => "super_admins#reset_password", as: "admin_reset_password"
  # =========================Restaurent==path============================
  get "branch/:id" => "restaurants#branch_view", as: "branch_show"
  get "restaurant/branch/:id" => "restaurants#restaurant_branch_menu", as: "admin_branch_menu_items"
  get "restaurant/branch/download_csv/:id" => "restaurants#download_csv", as: "download_csv"
  get "restaurant/list" => "restaurants#all_restaurant"
  get "restaurant/remove" => "restaurants#remove_restaurant"
  get "login_as_restaurant_owner" => "restaurants#login_as_restaurant_owner"
  get "login_as_enterprise_owner" => "enterprises#login_as_enterprise_owner"
  get "admin/branch/:id/coverage/area" => "restaurants#admin_branch_coverage_area", as: "admin_branch_coverage_area"
  get "admin_delete_branch_coverage_area" => "restaurants#admin_delete_branch_coverage_area"
  post "admin_branch_coverage_area_bulk_action" => "restaurants#admin_branch_coverage_area_bulk_action"

  post "add/menu/category" => "restaurants#add_menu_category"
  post "edit/menu/category" => "restaurants#edit_menu_category"

  get "edit/restaurant/user/:id" => "restaurants#edit_user", as: "edit_user_details"
  post "update/restaurant/user/:id" => "restaurants#update_user", as: "update_restaurant_user"

  post "add/menu/items" => "restaurants#add_menu_item", as: "add_menu_item"
  post "edit/menu/item" => "restaurants#edit_menu_item"
  get "new/menu/item/:branch_id" => "restaurants#new_menu_item", as: "new_menu_item"
  get "menu_category/item_list/:menu_category_id" => "restaurants#menu_category_item_list", as: "menu_category_item_list"
  get "update/menu/:menu_item_id/item/:branch_id" => "restaurants#update_menu_item", as: "update_menu_item"
  get "remove/menu/item/:id" => "restaurants#remove_menu_item"
  get "remove_menu_item_image" => "restaurants#remove_menu_item_image"
  get "remove/menu/category/:id" => "restaurants#remove_menu_category"
  get "remove/menu/addon/category/:id" => "branches#remove_menu_addon_category"
  get "item/:menu_item_id/addon/list/:branch_id" => "restaurants#item_addon_list", as: "item_addon_list"

  get "all/coverage/areas" => "areas#all_coverage_areas"
  get "new/coverage/areas" => "areas#new_coverage_areas"
  get "download_coverage_area_format" => "areas#download_coverage_area_format"
  post "upload_coverage_areas" => "areas#upload_coverage_areas"
  get "change/coverage/area" => "areas#change_coverage_area", as: "change_coverage_area"
  get "delete/coverage/area" => "areas#delete_coverage_area", as: "delete_coverage_area"
  post "add/coverage/area" => "areas#add_coverage_area", as: "add_coverage_area"
  post "edit/coverage/area" => "areas#edit_coverage_area", as: "edit_coverage_area"
  get "areas/zone_list" => "areas#zone_list", as: "area_zone_list"
  # =============categories path==================
  get "categories/list" => "categories#categories_list"
  post "remove/category" => "categories#remove_category"
  post "remove/week" => "offers#remove_week"
  post "add_category" => "categories#add_category"
  get "category/list" => "categories#categories_list"
  get "category/restaurant_list" => "categories#restaurant_list"
  # ======================Order Routes ======================================
  get "order/list" => "orders#order_list"
  get "order/transporter/history" => "orders#transporter_history"
  get "order/all_driver_locations" => "orders#all_driver_locations"
  get "transporter/order/list" => "orders#transporter_order_list", as: "transporter_order_list"
  get "admin_change_driver" => "orders#admin_change_driver"
  post "admin_update_driver" => "orders#admin_update_driver"
  get "order/refund_list" => "orders#refund_order_list"
  get "order/view_cancel_notes" => "orders#view_cancel_notes"
  get "admin/order/:id" => "orders#order_show", as: "order"
  get "driver_performance" => "orders#driver_performance", as: "driver_performance"
  get "admin_cancel_order_form" => "orders#cancel_order_form", as: "admin_cancel_order_form"
  post "admin_cancel_order" => "orders#cancel_order", as: "admin_cancel_order"
  post "admin_refund_order" => "orders#refund_order", as: "admin_refund_order"
  get "admin_take_order" => "orders#take_order", as: "admin_take_order"
  get "get_user_details" => "orders#get_user_details", as: "get_user_details"
  # ======================Offers Routes======================
  get "offers/list" => "offers#offers_list"
  get "offers/list/show" => "offers#offers_list_show"
  get "offer/show/:offer_id" => "offers#offer_show", as: "offer_show"
  post "accept/adds/request" => "offers#accept_adds_request"
  get "accept/add/:add_id" => "offers#accept_add_request"
  # ================notifications list======================
  get "notification/list" => "notifications#notification_list", as: "notification_list"

  # ==========================reports=========================
  get "area/orders" => "reports#area_orders"
  get "daily/orders" => "reports#day_orders"
  get "monthly/selling/items" => "reports#monthly_selling_items"

  post "change/restaurant/state" => "restaurants#change_restaurant_signed_state"
  post "upload/week/csv" => "welcome#upload_week_csv", as: "upload_week_csv"
  get "new/restaurant" => "restaurants#requested_restaurant"
  get "restaurant/pending_update_request" => "restaurants#pending_update_request"
  get "delete/restaurant/:id" => "restaurants#delete_restaurant"
  get "approve_name_change/restaurant/:id" => "restaurants#approve_name_change"
  get "reject_name_change/restaurant/:id" => "restaurants#reject_name_change"
  get "request/restaurant/details/:id" => "restaurants#restaurant_request_details", as: "view_request_restaurant_deatils"
  get "week/list" => "offers#week_list"
  get "week/new_week_list" => "offers#new_week_list"
  get "club/list" => "clubes#club_list"
  post "add/sub/category" => "clubes#add_club_sub_category"
  post "add/new/club" => "clubes#add_club"
  get "club/user/:id" => "clubes#club_user", as: "club_users"
  post "approved/restaurant" => "restaurants#approve_restaurant"
  post "reject/restaurant" => "restaurants#reject_restaurant_request"
  get "restaurant/document/download" => "restaurants#download_restaurant_doc"
  get "restaurant/transfer/money/data" => "users#all_payment_data_restaurant_wise"
  # ==========================================subscription=============================
  get "report/subscribe/restaurant/list" => "subscriptions#all_subscribe_restaurant"
  get "subscribe/branch/list" => "subscriptions#subscribe_branch"

  # ========================================================================
  get "app/settings" => "appsettings#settings", as: "app_settings"
  post "app/update/details" => "appsettings#update_app_settings", as: "update_settings"
  # post "app/price/percentage"=>"appsettings#update_admin_percentage",as: "admin_percentage"
  post "app/service/amount" => "appsettings#update_service_amount"
  get "admin/payment/invoice/:id" => "restaurants#restaurant_payment_invoice", as: "admin_payment_invoice"
  get "top/selling/reportes/:id" => "reports#top_selling_item_report", as: "admin_top_selling_item_report"

  get "high/sale/item/admin(/:restaurant_id)" => "reports#admin_top_selling_item", as: "admin_top_selling_item"

  get "admin/revenue/growth/lost/report/:id" => "reports#admin_revenue_growth_lost_report", as: "admin_revenue_growth_lost_report"
  get "admin/new/customer/report/:id" => "reports#admin_new_customer_report", as: "admin_new_customer_report"
  get "admin/cancel/order/report/:id" => "reports#admin_cancel_order_report", as: "admin_cancel_order_report"
  get "admin_approved_branches_report" => "reports#admin_approved_branches_report", as: "admin_approved_branches_report"
  get "admin_free_delivery_branches_report" => "reports#admin_free_delivery_branches_report", as: "admin_free_delivery_branches_report"
  get "admin_suggested_restaurants_report" => "reports#admin_suggested_restaurants_report", as: "admin_suggested_restaurants_report"
  get "admin_amount_transfers_report" => "reports#admin_amount_transfers_report", as: "admin_amount_transfers_report"
  get "admin_user_cart_report" => "reports#admin_user_cart_report", as: "admin_user_cart_report"
  get "admin_transporter_timings_report" => "reports#admin_transporter_timings_report", as: "admin_transporter_timings_report"
  get "admin_driver_timings" => "reports#admin_driver_timings", as: "admin_driver_timings"
  get "admin_driver_review_report" => "reports#admin_driver_review_report", as: "admin_driver_review_report"
  get "admin_driver_performance_report" => "reports#admin_driver_performance_report", as: "admin_driver_performance_report"
  get "admin_delete_driver_review" => "reports#admin_delete_driver_review", as: "admin_delete_driver_review"
  get "admin_points_redeemed_report" => "reports#admin_points_redeemed_report", as: "admin_points_redeemed_report"
  get "admin_branch_charges_report" => "reports#admin_branch_charges_report", as: "admin_branch_charges_report"
  get "admin_calendar_report" => "reports#admin_calendar_report", as: "admin_calendar_report"
  get "admin_calendar_restaurant_report" => "reports#admin_calendar_restaurant_report", as: "admin_calendar_restaurant_report"
  get "delivery_settle_amount_report" => "reports#delivery_settle_amount_report", as: "delivery_settle_amount_report"
  get "restaurant_settle_amount_report" => "reports#restaurant_settle_amount_report", as: "restaurant_settle_amount_report"
  get "restaurant_delivery_transaction_report" => "reports#restaurant_delivery_transaction_report", as: "restaurant_delivery_transaction_report"
  get "admin_mark_order_as_paid" => "reports#admin_mark_order_as_paid", as: "admin_mark_order_as_paid"
  post "admin_mark_bulk_order_as_paid" => "reports#admin_mark_bulk_order_as_paid", as: "admin_mark_bulk_order_as_paid"
  get "edit_order_transferrable_amount" => "reports#edit_order_transferrable_amount", as: "edit_order_transferrable_amount"
  post "update_order_transferrable_amount" => "reports#update_order_transferrable_amount", as: "update_order_transferrable_amount"
  get "admin_suggested_restaurants_users" => "reports#admin_suggested_restaurants_users", as: "admin_suggested_restaurants_users"
  get "send_suggested_restaurants_push_notification" => "reports#send_suggested_restaurants_push_notification", as: "send_suggested_restaurants_push_notification"
  post "send_suggested_restaurants_user_push_notification" => "reports#send_suggested_restaurants_user_push_notification", as: "send_suggested_restaurants_user_push_notification"
  get "user_cart_push_notification" => "reports#user_cart_push_notification", as: "user_cart_push_notification"
  post "send_user_cart_push_notification" => "reports#send_user_cart_push_notification", as: "send_user_cart_push_notification"
  get "rejected/restaurant" => "restaurants#rejected_restaurant"
  post "admin/noti/count" => "notifications#admin_notification_count"
  get  "admin/notifications" => "notifications#admin_notifications"
  get "admin_todays_report" => "reports#admin_todays_report", as: "admin_todays_report"
  get "admin_most_selling_item_report" => "reports#admin_most_selling_item_report", as: "admin_most_selling_item_report"
  get "admin_area_wise_report" => "reports#admin_area_wise_report", as: "admin_area_wise_report"
  get "admin_top_customer_report" => "reports#admin_top_customer_report", as: "admin_top_customer_report"

  get  "admin/advertisement/list" => "offers#admin_advertisement_list"
  get  "document/list" => "documents#document_list"
  post "upload/doc" => "documents#upload_doc"
  get  "restaurant/doc(/:restaurant_id)" => "documents#restaurant_document", as: "restaurant_document"
  post "reject/restaurant/doc" => "documents#reject_restaurant_doc"
  get "approve/restaurant/doc/:id" => "documents#approve_restaurant_doc", as: "approve_restaurant_doc"
  get "review/list" => "reviews#review_list"
  post "review/category" => "reviews#add_review_category"
  # ===================================Menu Item==========================================================
  get "update/menu/:category_id" => "restaurants#update_menu_category", as: "update_menu_category"
  get "add/new/menu/category/:branch_id" => "restaurants#add_new_menu_category"
  get "restaurant/details/:id" => "restaurants#restaurant_view", as: "restaurant_details"

  get "edit/rest/detail/:restaurant_id" => "restaurants#admin_edit_restaurant_details", as: "admin_edit_restaurant_details"
  post "update/rest/details/:restaurant_id" => "restaurants#admin_update_restaurant_details", as: "admin_update_restaurant_details"

  get "menu/item/addon/category/:branch_id" => "restaurants#add_addon_category", as: "menu_item_category"
  post "new/addon/category" => "restaurants#new_addon_category", as: "new_addon_category"
  get "menu/item/:branch_id/addon" => "restaurants#addon_item", as: "menu_item_addon"
  post "menu/item/addon" => "restaurants#new_addon_item", as: "add_new_addon_item"
  get "menu/item/:branch_id/addon/:addon_item_id" => "restaurants#edit_addon_item", as: "edit_addon_item"
  post "update/menu/item/addon" => "restaurants#update_addon_item", as: "update_menu_item_addon"
  get "remove/addon/item/:id" => "restaurants#remove_addon_item"
  get "menu/item/:branch_id/addon/category/:category_id" => "restaurants#edit_addon_category", as: "edit_addon_category"
  post "update/addon/category/details" => "restaurants#update_addon_category", as: "update_addon_category"
  post "update/notification" => "notifications#update_notification"
  get "restaurant/:restaurant_id/branch/offer/list" => "offers#branch_offer_list", as: "branch_offer_list"
  get "restaurant/:id/branch/offer" => "offers#add_branch_offer", as: "branch_offer"
  post "restaurant/branch/menu/new/offer" => "offers#branch_new_menu_offer"
  get "restaurant/menu/details/:restaurant_id" => "restaurants#restaurant_menu_managment", as: "restaurant_menu_managment"
  post "restaurant/menu/approve" => "restaurants#restaurant_menu_approve"
  post "restaurant/menu/reject" => "restaurants#restaurant_menu_reject"
  post "restaurant/menu/bulk_action" => "restaurants#menu_bulk_action"
  get "club/sub/category/:category_id" => "clubes#club_sub_category", as: "club_sub_category"
  post "edit/sub/category" => "clubes#edit_sub_category"
  post "edit/club/category" => "clubes#edit_club_category"
  get "bulk/notification" => "notifications#bulk_notification", as: "bulk_notification"
  post "send/bulk/notifications" => "notifications#send_bulk_notifications"
  get "club/notification" => "notifications#club_bulk_notification", as: "club_bulk_notification"
  post "send/club/notifications" => "notifications#send_club_user_bulk_notification"
  get "admin/over/all/restaurant/report" => "reports#over_all_report", as: "admin_over_all_report"
  get "restaurant/csv/data" => "restaurants#request_resturant_csv", as: "request_resturant_csv"
  get "edit/request/restaurant/:id" => "restaurants#edit_request_restaurant", as: "edit_request_restaurant"
  post "update/request/restaurant" => "restaurants#update_request_restaurant"
  post "update/category" => "categories#update_category"
  get "busy/restaurants" => "restaurants#busy_restaurants", as: "busy_restaurants"
  get "close/restaurants" => "restaurants#close_restaurants", as: "close_restaurants"
  get "reject/advertisement/list" => "offers#rejected_advertisement_list", as: "rejected_advertisement"
  get "area/wise/orders/report/:id" => "reports#area_orders_report", as: "area_orders_report"
  get "restaurant/owner/:id" => "restaurants#add_restaurant_owner", as: "restaurant_owner"
  post "restaurant/owner/info" => "restaurants#add_new_owner"
  post "admin/upload/contract" => "restaurants#admin_upload_contract_doc"
  post "branch/approved" => "restaurants#approved_branch"
  post "list/restaurant/csv/data" => "welcome#upload_restaurant_csv", as: "upload_restaurant_csv"
  get "edit/restaurant/branch/info" => "restaurants#edit_restaurant_branch", as: "edit_restaurant_branch"
  post "update/restaurant/branch/info" => "restaurants#update_restaurant_branch"
  get "coverage/area/list/:id" => "restaurants#download_area_upload_format_doc", as: "download_area_upload_format_doc"
  post "upload/area/doc" => "restaurants#upload_area_format_doc"
  get "restaurant/customer/list(/:restaurant_id)" => "users#restaurant_customer_list", as: "restaurant_customer_list"
  get "restaurant/customer/:user_id/transaction/details/:restaurant_id" => "users#customer_wallet", as: "customer_wallet"
  get "contact/list" => "subscriptions#contact_list", as: "contact_list"
  post "restaurant/change/password" => "users#restaurant_reset_password"
  get "scrap/menu(/:restaurant_id)" => "welcome#scrap_menu", as: "scrap_menu"
  post "restaurant/scrap/menu" => "welcome#scraped_menu_data", as: "scraped_menu_data"
  get "menu/html/data" => "welcome#menu_html"
  get "remove/restaurant/branch/:id" => "restaurants#remove_restaurant_branch"
  get "remove/restaurant/rating/:id" => "restaurants#restaurant_rating_remove"
  get "/remove/restaurant/order/rating/:id" => "restaurants#restaurant_order_rating_remove"
  post "/change/email" => "users#chnage_email"
  # =============Roles path==================
  get "roles/list" => "roles#roles_list"
  post "update/role" => "roles#update_role"
  post "remove/role" => "roles#remove_role"
  # post "remove/week" => "offers#remove_week"
  post "add_role" => "roles#add_role"
  # get "category/list" => "categories#categories_list"
  # ============================Partner Routes======================================

  namespace :delivery_company do
    get "dashboard" => "delivery_partners#dashboard"
    get "transporters" => "delivery_partners#transporters"
    get "current_drivers_list" => "delivery_partners#current_drivers_list"
    get "new_transporters" => "delivery_partners#new_transporters"
    post "add_transporters" => "delivery_partners#add_transporters"
    post "update_transporters" => "delivery_partners#update_transporters"
    get "remove_transporter" => "delivery_partners#remove_transporter"
    get "edit_password" => "delivery_partners#edit_password"
    post "change_password" => "delivery_partners#change_password"
    get "active_orders_list" => "delivery_partners#active_orders_list"
    post "change_driver" => "delivery_partners#change_driver"
    get "track_drivers" => "delivery_partners#track_drivers"
    get "free_driver" => "delivery_partners#free_driver"
    get "settle_amount" => "delivery_partners#settle_amount"
    post "send_amount_settle_approval" => "delivery_partners#send_amount_settle_approval"
    get "driver_shift_list" => "delivery_partners#driver_shift_list"
    get "ious_list" => "delivery_partners#ious_list"
    post "paid/iou" => "delivery_partners#paid_iou"
    get "driver_review_report" => "delivery_partners#driver_review_report"
    get "driver_timing_report" => "delivery_partners#driver_timing_report"
    get "driver_timing" => "delivery_partners#driver_timing"

    resources :delivery_company_shifts do
      get :free_driver_list, on: :member
      post :add_driver_to_shift, on: :collection
      get :remove_driver_from_shift, on: :collection
    end
  end

  resources :restaurants do 
    get 'filter_branches_by_country' => 'brands#filter_branches_by_country'
    get 'filter_coverage_areas_by_country' => 'brands#filter_coverage_areas_by_country'
    get 'filter_branch_by_country' => 'brands#filter_branch_by_country'
  end

  
  namespace :inventory do
    resources :restaurants do
      get 'filter_source_by_type' => 'transfer_orders#filter_source_by_type'
      get 'filter_destination_by_type' => 'transfer_orders#filter_destination_by_type'
      resources :recipes do
        get 'recipe_list'
        collection do
          get 'get_portion_units', to: 'recipes#get_portion_units', as: :get_portion_units
        end
      end
      resources :inventories do
        collection do
          get 'soh'
        end 
      end
      resources :transfer_orders do
        post 'process_transfer'
        collection do
          get 'display_article_details'
          get 'approve_orders'
          get 'process_transfer_orders'
        end
      end
      resources :purchase_orders do
        resources :receive_orders
        collection do
          get 'dashboard'
          get 'book_orders'
          post 'reject_purchase_order'
          get 'display_article_details'
        end
      end
      resources :receive_orders do
        collection do
          get 'receive_po_orders'
          get 'reject_orders'
          post 'reject_receive_order'
          get 'display_article_details'
        end
      end
    end
  end
  
  namespace :finance do
    resources :restaurants do
      resources :account_types
      resources :account_categories
    end
  end

  namespace :setup do
    resources :restaurants do
      resources :units
    end
  end

  namespace :master do
    resources :restaurants do
      resources :over_groups
      resources :major_groups
      resources :item_groups
      resources :recipe_groups
      resources :combo_meal_groups
      resources :store_types
      resources :production_groups
      resources :brands
      resources :stations do 
        collection do 
          get :printers
          post :add_printers
        end
      end
      resources :stores
      resources :articles
      get 'filter_other_groups_by_type' => 'recipes#filter_other_groups_by_type'
      get 'filter_groups_by_type' => 'articles#filter_groups_by_type'
      get 'filter_item_groups_by_type' => 'item_groups#filter_groups_by_type'
      get 'filter_over_groups_by_type' => 'major_groups#filter_over_groups_by_type'
    end
  end

  namespace :influencer do
    get "dashboard" => "influencer_users#dashboard"
    get "available_points" => "influencer_users#available_points"
    get "sold_points" => "influencer_users#sold_points"
    get "referrals" => "influencer_users#referrals"
  end

  namespace :hrms do
    resources :restaurants do
      resources :shifts do
        collection do
          get 'assign_shift'
          # get 'add_event_date'
          # get 'edit_event_date'
          # get 'remove_event_date'
        end
      end
    end
  end

  namespace :hrms do
    resources :shifts do
      collection do
        get 'add_event_date'
        get 'edit_event_date'
        get 'remove_event_date'
        get 'schedule_shift'
        post 'assign_employee'
        get 'fetch_station_employees'
        # get 'event_date_list'
        get 'delete_employee'
      end
    end
  end

  namespace :hrms do
    resources :shifts do 
      get :event_date_list, on: :member
    end
  end

  namespace :business do
    resources :kds do 
      collection do
          get 'dashboard'
          get 'find_country_based_branch'
          get 'find_branch_based_station'
          get  'change_order_color'
      end
    end
    resources :catering_schedules
    get "partner/kds_color_setting(/:restaurant_id)" => "partners#kds_color_setting", as: "partner_kds_color_setting"
    get "partner/change_kds_type" => "partners#change_kds_type", as: "partner_change_kds_type"
    get "partner/save_kds_color" => "partners#save_kds_color", as: "partner_save_kds_color"
    get "partner/kds_menu(/:restaurant_id)" => "partners#kds_menu", as: "partner_kds_menu"
    namespace :setup do
      resources :restaurants do
       resources :card_types
       resources :manuals
       resources :manual_categories
       resources :chapters
     end
      resources :banks
      resources :stages
      resources :document_stages do
        collection do 
          post 'document_upload'
          get 'new_document_upload'
          get 'document_upload_list'
          get 'generate_qr_code'
          get 'document_detail_list'
          get 'stages'
          get 'stage_uploaded_file'
          get 'find_account_category'
        end
        member do
         get 'edit_document_upload'
         patch 'update_document_upload'
         get 'show_upload_document'
        end
      end

      resources :vendors do
        collection do
          post 'change_vendors_state'
        end
      end    
    end
    namespace :employee_master do
      resources :restaurants do
       resources :departments
       resources :designations
       resources :user_privileges do
          collection do
            get 'find_country_based_branch'
            get 'find_designation_based_department'
          end
       end
      end 
      resources :reimbersments
      resources :loan_types
      resources :asset_categories
    end

    namespace :task_management do 
      resources :restaurants do
        resources :task_types do
          collection do
            get 'find_country_based_branch'
          end
        end
        resources :task_categories do
          collection do
            get 'find_country_based_branch'
            get 'find_branch_based_task_type'
          end
        end
        resources :task_sub_categories do
          collection do
            get 'find_country_based_branch'
            get 'find_branch_based_task_type'
            get 'find_task_category_based_task_type'
          end
        end
        resources :task_activities do
          collection do
            get 'find_country_based_branch'
            get 'find_branch_based_task_type'
            get 'find_task_category_based_task_type'
          end
        end
        resources :task_lists do
          collection do
            get 'find_country_based_branch'
            get 'find_branch_based_task_type'
            get 'find_task_category_based_task_type'
            get 'find_task_activity_based_task_category'
            get 'find_task_sub_category_based_task_category'
          end
        end
        resources :assign_tasks do
          collection do
            get 'find_country_based_branch'
            get 'find_designation_based_department'
            get 'find_employee_based_designation'
            get 'dashboard'
            get 'find_task_list_based_branch'
          end
        end
      end  
    end

    namespace :asset_management do
       resources :asset_types
       resources :assets do
        collection do
          get 'find_asset_type_list'
        end
        get :view_image, on: :member
        get :view_QR_Code, on: :member

       end
    end
    namespace :hrms do
      resources :employees do 
        collection do
          get 'find_country_based_branch'
          get 'dashboard'
          get 'reporting_to_list'
          get 'department_designation'
          get 'review_employee'
          patch 'approve_employee'
          post 'reject_employee'
          get 'rejected_employee'
          post 'upload_passport'
          get 'auto_populate_info'
        end
      end

      resources :family_details do 
        collection do
          get 'dashboard'
          get 'reporting_to_list'
          get 'find_country_based_branch'
        end
      end

      resources :assign_assets do 
        collection do
          get 'dashboard'
          get 'department_designation'
          get 'find_asset_list'
          get 'hand_over_list'
        end

        member do
         get 'hand_over'
         get 'view_image'
        end
      end

      resources :salaries do 
        collection do
          get 'get_user_detail'
        end
      end

      resources :loan_revises do 
        collection do
          get 'dashboard'
          patch 'approve_loan_revise'
          post 'reject_loan_revise'
          get 'loan_list'
          get 'loan_details'
        end
      end

      resources :loan_settlements do 
        collection do
          get 'dashboard'
          get 'loan_list'
          get 'loan_details'
          patch 'approve_loan_settelment'
          post 'reject_loan_settelment'
        end
      end

      resources :reimbursements do
        collection do
          get 'review_reimbursement'
          patch 'approve_reimbursement'
          post 'reject_reimbursement'
          get 'rejected_reimbursement'
        end
      end
      resources :loans do
        collection do
          get 'review_loan'
          patch 'approve_loan'
          post 'reject_loan'
          get 'rejected_loan'
          get 'department_designation'
        end
      end

      resources :job_positions do
        collection do
          get 'department_designation'
          get 'find_country_based_branch'
        end
      end

      resources :job_applications do
        member do
          get 'approve_application'
          get 'hold_application'
          get 'unhold_application'
        end
        collection do
          get 'resume_list'
        end
      end
      post "/reject_application" => "job_applications#reject_application"
      get "/approved_application" => "job_applications#approved_application"
      get "/rejected_application" => "job_applications#rejected_application"
      get "/holded_application" => "job_applications#holded_application"
    end


    namespace :task_reports do
      resources :task_percentages do 
        collection do 
          get 'dashboard'
          get 'find_country_based_branch'
          get 'find_designation_based_department'
          get 'find_employee_based_designation'
        end
          get 'assigned_tasks'
      end
    end

    resources :enterprises do
      collection do
        get 'dashboard'
      end
    end

    namespace :pos_management do
      resources :floor_managements
    end

    namespace :spot_checks do
      resources :restaurants do
        resources :cash_spot_checks
      end
    end

    resources :employees
    get "login" => "partners#login", as: "partner_login"
    post "partner/auth" => "partners#partner_auth", as: "partner_auth"
    get "partner/dashboard(/:restaurant_id)" => "partners#dashboard", as: "partner_dashboard"
    get "partner/enterprise_dashboard(/:enterprise_id)" => "partners#enterprise_dashboard", as: "enterprise_dashboard"

    # get "partner/kds_color_setting(/:restaurant_id)" => "partners#kds_color_setting", as: "partner_kds_color_setting"
    # get "partner/change_kds_type" => "partners#change_kds_type", as: "partner_change_kds_type"
    # get "partner/save_kds_color" => "partners#save_kds_color", as: "partner_save_kds_color"
    # get "partner/kds_menu(/:restaurant_id)" => "partners#kds_menu", as: "partner_kds_menu"

    post "partner/app_orders_list" => "partners#app_orders_list", as: "partner_app_orders_list"
    post "partner/save_other_order_driver" => "partners#save_other_order_driver", as: "partner_save_other_order_driver"
    post "partner/update_order_status" => "partners#update_order_status", as: "partner_update_order_status"
    post "partner/apply_coupon_code" => "partners#apply_coupon_code", as: "partner_apply_coupon_code"

    get "partner/quick_pay_popup(/:restaurant_id)" => "partners#quick_pay_popup", as: "pos_quick_pay_popup"
    get "partner/get_discount_percentage" => "partners#get_discount_percentage", as: "get_discount_percentage"
    get "partner/apply_discount_percentage" => "partners#apply_discount_percentage", as: "apply_discount_percentage"
    delete "partner/delete_discount_percentage" => "partners#delete_discount_percentage", as: "delete_discount_percentage"

    get 'partner/pos_dashboard/:restaurant_id/currency_types' => 'currency_types#index', as: :currency_types

    get 'partner/pos_dashboard/:restaurant_id/currency_types/new' => 'currency_types#new', as: :new_currency_types
    post 'partner/pos_dashboard/:restaurant_id/currency_types' => 'currency_types#create', as: :create_currency_types
    get 'partner/pos_dashboard/:restaurant_id/currency_types/:id/edit' => 'currency_types#edit', as: :edit_currency_types
    patch 'partner/pos_dashboard/:restaurant_id/currency_types/:id' => 'currency_types#update', as: :update_currency_types
    delete 'partner/pos_dashboard/:restaurant_id/currency_types/:id' => 'currency_types#destroy', as: :delete_currency_types


    get 'partner/pos_dashboard/:restaurant_id/cash_types' => 'cash_types#index', as: :cash_types
    get 'partner/pos_dashboard/:restaurant_id/cash_types/new' => 'cash_types#new', as: :new_cash_types
    post 'partner/pos_dashboard/:restaurant_id/cash_types' => 'cash_types#create', as: :create_cash_types
    get 'partner/pos_dashboard/:restaurant_id/cash_types/:id/edit' => 'cash_types#edit', as: :edit_cash_types
    patch 'partner/pos_dashboard/:restaurant_id/cash_types/:id' => 'cash_types#update', as: :update_cash_types
    delete 'partner/pos_dashboard/:restaurant_id/cash_types/:id' => 'cash_types#destroy', as: :delete_cash_types

    

    get "partner/pos_dashboard(/:restaurant_id)" => "partners#pos_dashboard", as: "partner_pos_dashboard"
    get "partner/pos_dashboard_terminal(/:restaurant_id)" => "partners#pos_dashboard_terminal", as: "partner_pos_dashboard_terminal"
    get "partner/find_country_based_branch" => "partners#find_country_based_branch"
    get "partner/find_pos_tables" => "partners#find_pos_tables"
    get "partner/pos_new_check(/:branch_id)" => "partners#pos_new_check", as: "partner_pos_new_check"
    post "partner/pos_new_check_begin_check_by_name" => "partners#pos_new_check_begin_check_by_name", as: "partner_pos_new_check_begin_check_by_name"
    get "partner/pos_cancel_transaction(/:table_id)" => "partners#pos_cancel_transaction", as: "pos_cancel_transaction"
    post "partner/store_pos_table" => "partners#store_pos_table", as: "partner_store_pos_table"
    post "partner/pos_payment" => "partners#pos_payment", as: "partner_pos_payment"
    post "partner/remain_payment_popup" => "partners#remain_payment_popup", as: "partner_remain_payment_popup"
    post "partner/pos_share_item_popup" => "partners#pos_share_item_popup", as: "partner_pos_share_item_popup"
    post "partner/cover_pos_table" => "partners#cover_pos_table", as: "partner_cover_pos_table"
    post "partner/pos_begin_table" => "partners#pos_begin_table", as: "partner_pos_begin_table"
    post "partner/pos_bind_dinein_table" => "partners#pos_bind_dinein_table", as: "partner_pos_bind_dinein_table"
    post "partner/pos_status_change" => "partners#pos_status_change", as: "partner_pos_status_change"
    post "partner/pos_transfer_table" => "partners#pos_transfer_table", as: "partner_pos_transfer_table"
    post "partner/pos_pickup_check" => "partners#pos_pickup_check", as: "partner_pos_pickup_check"
    post "partner/pos_pickup_check_list" => "partners#pos_pickup_check_list", as: "partner_pos_pickup_check_list"
    post "partner/pos_transfer_table_list" => "partners#pos_transfer_table_list", as: "partner_pos_transfer_table_list"
    post "partner/pos_seach_customer" => "partners#pos_seach_customer", as: "partner_pos_seach_customer"
    post "partner/pos_dashboard_dine_list" => "partners#pos_dashboard_dine_list", as: "partner_pos_dashboard_dine_list"
    post "partner/pos_split_check" => "partners#pos_split_check", as: "pos_split_check"
    post "partner/pos_no_of_chair_per_table" => "partners#pos_no_of_chair_per_table", as: "pos_no_of_chair_per_table"
    post "partner/pos_save_comment" => "partners#pos_save_comment", as: "pos_save_comment"
    post "partner/pos_save_item_comment" => "partners#pos_save_item_comment", as: "pos_save_item_comment"
    post "partner/pos_no_of_table" => "partners#pos_no_of_table", as: "pos_no_of_table"
    post "partner/remove_pos_transaction" => "partners#remove_pos_transaction", as: "remove_pos_transaction"
    get "partner/pos_new_transaction(/:restaurant_id)" => "partners#pos_new_transaction", as: "partner_pos_new_transaction"
    post "partner/pos_new_transaction/split_checks" => "partners#split_checks", as: "split_checks"
    post "partner/pos_new_transaction/share_check" => "partners#share_check", as: "share_check"
    post "partner/pos_new_transaction/assign_driver" => "partners#assign_driver", as: "assign_driver"
    post "partner/pos_new_transaction/:user_id/get_addresses" => "partners#get_addresses", as: "get_addresses"
    post "partner/pos_new_transaction/:address_id/minimum_coverage" => "partners#minimum_coverage", as: "minimum_coverage"
    post "partner/pos_new_transaction/create_customer_check" => "partners#create_customer_check", as: "create_customer_check"
    post "partner/pos_new_transaction/remove_last_check" => "partners#remove_last_check", as: "remove_last_check"
    post "partner/pos_new_transaction/cancel_check" => "partners#cancel_check", as: "cancel_check"
    post "partner/pos_new_transaction/search_check" => "partners#search_check", as: "search_check"
    post "partner/pos_new_transaction/add_check/:parent_check_id" => "partners#add_check", as: "add_check"
    delete "partner/pos_new_transaction/remove_check" => "partners#remove_check", as: "remove_check"
    post "partner/pos_new_transaction(/:restaurant_id)/restaurant_table/:table_id/begin_check" => "partners#begin_check", as: "begin_check"
    post "partner/pos_new_transaction/:table_id/transfer_check_detail" => "partners#transfer_check_detail", as: "transfer_check_detail"
    post "partner/pos_new_transaction/transfer_check" => "partners#transfer_check", as: "transfer_check"
    get "partner/pos_menu_items(/:category_id)" => "partners#pos_menu_items", as: "partner_pos_menu_items"
    get "partner/pos_menu_categories(/:restaurant_id)" => "partners#pos_menu_categories", as: "partner_pos_menu_categories"
    post "partner/pos_menu_categories(/:table_id)/menu_item/(/:menu_item_id)" => "partners#add_pos_transaction", as: "add_pos_transaction"
    post "partner/pos_menu_categories(/:table_id)/pos_check/:pos_check_id/print_check" => "partners#print_check", as: "print_check"
    post "partner/pos_menu_categories(/:table_id)/menu_item/:pos_check_id/check_item_addon" => "partners#check_item_addon", as: "check_item_addon"
    post "partner/pos_menu_categories(/:table_id)/update_seat_no" => "partners#update_seat_no", as: "update_seat_no"
    post "partner/pos_menu_categories(/:restaurant_id)/restaurant_table(/:table_id)/restaurant_check/:check_id/save_check" => "partners#save_check", as: "save_check"
    patch "partner/pos_new_transaction(/:restaurant_id)/pickup_tables" => "partners#pickup_tables", as: "pickup_tables"
    patch "partner/pos_new_transaction(/:restaurant_id)/open_check_number" => "partners#open_check_number", as: "open_check_number"
    delete "partner/pos_new_transaction/pos_payment/:payment_id/delete_payment" => "partners#delete_payment", as: "delete_payment"
    patch "partner/pos_menu_categories(/:table_id)/pos_table_seat" => "partners#pos_table_seat", as: "pos_table_seat"
    post "partner/pos_menu_categories(/:table_id)/menuaddon_item/(/:menu_item_id)" => "partners#add_menu_addon_pos_transaction", as: "add_menu_addon_pos_transaction"
    post "partner/pos_menu_categories/pos_check/:pos_check_id/driver_list" => "partners#driver_list", as: "partner_driver_listing"
    delete "partner/pos_menu_categories(/:restaurant_id)/clear_pos_transaction" => "partners#clear_pos_transaction", as: "clear_pos_transaction"
    get "partner/logout" => "partners#partner_logout", as: "partner_logout"
    get "manager/dashboard" => "partners#manager_dashboard", as: "manager_dashboard"
    get "kitchen/manager/dashboard(/:restaurant_id)" => "partners#kitchen_manager_dashboard", as: "kitchen_manager_dashboard"
    get "busy/restaurant/details/:restaurant_id" => "reports#business_busy_restaurants", as: "busy_restaurants"
    get "close/restaurant/details/:restaurant_id" => "reports#business_close_restaurants", as: "close_restaurants"
    get "customer_master/restaurant/details/:restaurant_id" => "reports#pos_customer_master", as: "pos_customer_master"
    get "brand_master/restaurant/details/:restaurant_id" => "reports#pos_brand_master", as: "pos_brand_master"
    get "employee_master/restaurant/details/:restaurant_id" => "reports#pos_employee_master", as: "pos_employee_master"
    get "setup_master/restaurant/details/:restaurant_id" => "reports#pos_setup_master", as: "pos_setup_master"
    get "manager/busy/restaurants/details/:branch_id" => "reports#manager_busy_restaurants", as: "manager_busy_restaurants"
    get "manager/close/restaurants/details/:branch_id" => "reports#manager_close_restaurants", as: "manager_close_restaurants"
    get 'partner/pos_dashboard/:restaurant_id/order_types' => 'order_types#index', as: :order_types
    get 'partner/pos_dashboard/:restaurant_id/order_types/new' => 'order_types#new', as: :new_order_types
    post 'partner/pos_dashboard/:restaurant_id/order_types' => 'order_types#create', as: :create_order_types
    get 'partner/pos_dashboard/:restaurant_id/order_types/:id/edit' => 'order_types#edit', as: :edit_order_types
    patch 'partner/pos_dashboard/:restaurant_id/order_types/:id' => 'order_types#update', as: :update_order_types
    delete 'partner/pos_dashboard/:restaurant_id/order_types/:id' => 'order_types#destroy', as: :delete_order_types

    get 'partner/pos_dashboard/:restaurant_id/payment_methods' => 'payment_methods#index', as: :payment_methods
    get 'partner/pos_dashboard/:restaurant_id/payment_methods/new' => 'payment_methods#new', as: :new_payment_methods
    post 'partner/pos_dashboard/:restaurant_id/payment_methods' => 'payment_methods#create', as: :create_payment_methods
    get 'partner/pos_dashboard/:restaurant_id/payment_methods/:id/edit' => 'payment_methods#edit', as: :edit_payment_methods
    patch 'partner/pos_dashboard/:restaurant_id/payment_methods/:id' => 'payment_methods#update', as: :update_payment_methods
    delete 'partner/pos_dashboard/:restaurant_id/payment_methods/:id' => 'payment_methods#destroy', as: :delete_payment_methods


    get "manual/order(/:restaurant_id)" => "partners#manual_order", as: "manual_order"
    post "create_manual_order_cart" => "partners#create_manual_order_cart"
    post "create_new_customer_begin_check" => "partners#create_new_customer_begin_check"
    post "create_new_customer_check_id" => "partners#create_new_customer_check_id"
    post "create_manual_order" => "partners#create_manual_order"
    get "send_customer_order_mail" => "partners#send_customer_order_mail"
    get "show_branch_areas" => "partners#show_branch_areas"
    get "show_category_items" => "partners#show_category_items"
    get "show_item_addons" => "partners#show_item_addons"
    get "add_item_row" => "partners#add_item_row"
    get "address_details" => "partners#address_details"
    get "area_details" => "partners#area_details"
    get "requested_orders_list" => "partners#requested_orders_list"
    get "remove_requested_order" => "partners#remove_requested_order"

    get "orders(/:restaurant_id)" => "orders#index", as: "orders"
    get "branch/order" => "orders#maneger_branch_order"
    get "order(/:restaurant_id)/:id" => "orders#show", as: "view_order"
    get "branches/list" => "branches#index"
    get "branch/:id" => "branches#view_branch", :as => "branchshow"
    get "restaurant(/:restaurant_id)" => "branches#restaurant", as: "restaurant"
    get "order/invoice(/:restaurant_id)/:id" => "orders#order_invoice", :as => "order_invoice"
    get "transporters(/:restaurant_id)" => "users#index", as: "transporters"
    get "transporters(/:restaurant_id)/track_drivers" => "users#track_drivers", as: "transporter_track_drivers"
    get "transporters/branch/track_drivers" => "users#track_drivers", as: "manager_track_drivers"
    get "managers(/:restaurant_id)" => "users#all_managers", as: "managers"
    get "managers/change_branches/:id" => "users#change_branches", as: "change_branches"
    post "managers/update_branches" => "users#update_branches", as: "update_branches"
    get "kitchen/managers(/:restaurant_id)" => "users#all_kitchen_managers", as: "kitchen_managers"
    get "add/transporter(/:restaurant_id)" => "users#add_transporter", as: "add_transporter"
    post "new/transporter" => "users#create"
    post "/employee/update" => "users#update", as: "edit_employee"
    get "user/edit(/:restaurant_id)" => "users#business_edit", as: "user_edit"
    get "restaurant/branches(/:restaurant_id)" => "branches#resturant_branch", as: "resturant_branch"
    get "restaurant/branches(/:restaurant_id)/customers_list" => "branches#customers_list", as: "customers_list"
    post "restaurant/branches/new_customer_master_key" => "branches#new_customer_master_key", as: "new_customer_master_key"
    post "restaurant/branches/bulk_customer_creation" => "branches#bulk_customer_creation", as: "bulk_customer_creation"
    get "restaurant/branches(/:restaurant_id)/download_template" => "branches#download_template", as: "download_template"
    get "manager/branches" => "branches#manager_restaurant_branch", as: "manager_restaurant_branch"
    get "restaurant/branch/:id(/:restaurant_id)" => "branches#branch_menu", as: "branch_menu_items"
    post "branch/upload_csv" => "branches#upload_csv", as: "upload_csv"
    get "branch/orders/:id" => "orders#branch_order", as: "branch_orders"
    get "branch/coverage/area/:branch_id(/:restaurant_id)" => "branches#branch_coverage_area", as: "branch_coverage_area"
    post "order/action" => "orders#web_order_action"
    post "order/move/kitchen" => "orders#web_order_move_Kitchen"
    post "transporter/assign" => "orders#web_add_transporter_to_order"
    get "transporter/assign" => "orders#web_add_transporter_to_order"
    get "food_club/transporter/assign" => "orders#assign_foodclub_driver"
    get "transporter/auto_assign" => "orders#assign_nearest_transporter_to_order"
    get "transporter/assign_dine_in_order" => "orders#assign_dine_in_order"
    post "change/order/stage" => "orders#web_order_update_stage"
    post "order/delivered" => "orders#web_order_delivered"
    get "advertisement/list(/:restaurant_id)" => "offers#advertisement_list", as: "advertisement_list"
    get "add/advertisement(/:restaurant_id)" => "offers#add_advertisement", as: "add_advertisement"

    get "offers/update_pending_offer" => "offers#update_pending_offer"
    post "offers/edit_pending_offer" => "offers#edit_pending_offer"
    post "reports/budget/sales/csv" => "reports#budget_vs_sales_csv"
    get "reports/area/wise/csv" => "reports#area_wise_csv"

    get "top/selling/item(/:restaurant_id)" => "reports#top_selling_item", as: "top_selling_item"
    get "new/customer/reports(/:restaurant_id)" => "reports#new_customer_report", as: "new_customer_reports"
    get "revenue/reports(/:restaurant_id)" => "reports#revenue_growth_lost_report", as: "revenue_reports"
    get "cancel/order/reports(/:restaurant_id)" => "reports#cancel_order_reports", as: "cancel_order_reports"
    get "add/branch(/:restaurant_id)" => "branches#add_branch", as: "add_branch"
    get "add_new_branch_timing" => "branches#add_new_branch_timing", as: "add_new_branch_timing"
    post "new/branch" => "branches#add_new_branch"
    # get "top/selling/item/csv"=>"reports#top_selling_item_csv"
    get "top/selling" => "reports#top_selling_item_csv"
    get "revenue/growth/csv" => "reports#revenue_growth_lost_report_csv"
    get "cancel/order/report" => "reports#cancel_order_csv"
    get "new/customer/report" => "reports#new_customer_report_csv"
    get "edit/branch(/:restaurant_id)/:id" => "branches#edit_branch", as: "edit_branch"
    post "update/branch/info" => "branches#update_branch_info"
    get "branch/over/all/reportes(/:restaurant_id)" => "reports#branch_over_all_reportes", as: "branch_over_all_reportes"
    post "new/advertisement" => "offers#add_new_advertisement"
    get "notifications(/:restaurant_id)" => "notifications#business_notifications", as: "notifications"
    post "noti/count" => "notifications#business_notification_count"
    post "subscribe/report" => "branches#subscribe_report"
    get "order/tracking(/:restaurant_id)/:id" => "orders#live_order_tracking", as: "order_live_tracking"
    post "upload/contract(/:restaurant_id)" => "branches#upload_contract_doc", as: "upload_contract_doc"
    get "document/list(/:restaurant_id)" => "documents#document_list", as: "document_list"
    get "budget/list(/:restaurant_id)" => "budgets#budget_list", as: "budget_list"
    post "add/budget" => "budgets#add_budget"
    get "tasks_list/index" => "tasks_list#index", as: "tasks_list"
    get "tasks_list/assigned_task" => "tasks_list#assigned_task", as: "assigned_task"
    get "tasks_list/completed_task" => "tasks_list#completed_task", as: "completed_task"
    get "tasks_list/dashboard" => "tasks_list#dashboard", as: "task_dashboard"
    get "tasks_list/complete_task" => "tasks_list#complete_task"
    patch "tasks_list/upload_complete_task" => "tasks_list#upload_complete_task"

    

    #===============================Menu Item========================================
    get "add/branch/:branch_id/menu/item" => "branches#add_menu_item", as: "add_branch_menu"
    post "add/branch/new/menu/item" => "branches#add_new_menu_item"
    get "branch/:branch_id/menu/category(/:restaurant_id)" => "branches#add_menu_category", as: "branch_menu_category"
    post "branch/new/menu/item/category" => "branches#menu_category_add"
    get "branch/:branch_id/menu/:category_id" => "branches#update_branch_menu_category", as: "update_branch_menu_category"
    post "branch/menu/category/update" => "branches#edit_branch_menu_category"
    get "branch_menu_category/item_list/:menu_category_id" => "branches#branch_menu_category_item_list", as: "branch_menu_category_item_list"
    get "edit/branch/:branch_id/menu/:menu_item_id" => "branches#edit_branch_menu_item", as: "edit_branch_menu_item"
    post "update/branch/menu/item" => "branches#update_branch_menu_item"
    get "branch/:branch_id/addon/list" => "branches#menu_item_addon_list", as: "menu_item_addon_list"
    get "branch/menu/:branch_id/addon/category" => "branches#add_manu_addon_category", as: "manu_addon_category"
    post "branch/menu/item/addon" => "branches#new_menu_addon_category"
    get "branch/menu/addon/category/:category_id" => "branches#edit_menu_addon_category", as: "edit_menu_addon_category"
    post "branch/menu/item/addon/category" => "branches#update_menu_addon_category"
    get "branch/menu/:branch_id/addon" => "branches#menu_addon_item", as: "menu_addon_item"
    post "branch/menu/item/addon/item" => "branches#menu_new_addon_item"
    get "branch/:branch_id/addon/:addon_item_id" => "branches#edit_menu_addon_item", as: "edit_menu_addon_item"
    post "update/branch/menu/item/addon" => "branches#update_menu_addon_item"
    get "remove/branch/menu/addon/item/:id" => "branches#remove_menu_addon_item", as: "remove_menu_addon_item"
    get "branch/offer/list(/:restaurant_id)" => "offers#offer_list", as: "offer_list"
    get "branch/menu/offer(/:restaurant_id)" => "offers#add_offer", as: "add_menu_offer"
    get "branch/admin/offer/percentage" => "offers#admin_offer_percentage", as: "admin_offer_percentage"
    post "branch/menu/offer/add" => "offers#new_menu_offer"
    post "update/business/notification" => "notifications#update_business_notification"
    get "budget/sales/report(/:restaurant_id)" => "reports#budget_sales_report", as: "budget_sales_report"
    get "branch/coverage_area/:coverage_area_id" => "branches#update_coverage_area", as: "update_coverage_area"
    get "branch/ious/list(/:restaurant_id)" => "ious#iou_list", as: "branch_ious_list"
    post "business/iou/paid" => "ious#business_paid_iou"
    get "budget_sales_report_csv" => "reports#budget_sales_report_csv"

    post "business/update/transporter" => "orders#business_update_transporter_in_order"
    get "branch/menu/offer(/:restaurant_id)/:offer_id" => "offers#update_offer", as: "menu_offer"
    post "branch/menu/offer/update" => "offers#edit_offer"
    post "remove/menu/offer" => "offers#remove_offer"
    post "edit/branch/coverage/area" => "branches#edit_coverage_area"
    post "change/password" => "users#reset_password"
    get "remove/employee/:id/:role" => "users#remove_employee"
    # get "add/new/coverage/area/:branch_id"=>"branches#add_branch_coverage_area",as: "add_branch_coverage_area"
    # post "branch/new/coverage/area"=>"branches#branch_new_coverage_area"
    get "add/new/coverage/area(/:restaurant_id)" => "branches#add_branch_coverage_area", as: "add_branch_coverage_area"
    post "branch/new/coverage/area" => "branches#branch_new_coverage_area"
    post "change/branch/busy/state" => "branches#change_branch_busy_state"
    get "branch/:id/cuisine(/:restaurant_id)" => "categories#category_list", as: "cuisine_list"
    post "branch/cuisine" => "categories#add_branch_category"
    post "branch/cuisine/remove" => "categories#remove_branch_category"
    get "restaurant/details/:restaurant_id" => "branches#edit_restaurant_details", as: "edit_restaurant_details"
    post "update/restaurant/details" => "branches#update_restaurant_details"
    get "edit/dine_in/order" => "orders#edit_dine_in_order", as: "edit_dine_in_order"
    post "update/dine_in/order" => "orders#update_dine_in_order", as: "update_dine_in_order"
    get "area/wise/reports(/:restaurant_id)" => "reports#area_wise_report", as: "area_wise_reports"
    get "pending/ads/list(/:restaurant_id)" => "offers#pending_advertisement_list", as: "pending_advertisement_list"
    get "business/ads/list/:offer_id" => "offers#offer_show", as: "business_offer_show"
    get "branch/daily/dishes/:branch_id/category" => "branches#add_daily_dishes", as: "add_daily_dishes"
    post "branch/daily/dishes" => "branches#daily_dishes"

    get "branch/:branch_id/daily/dishes/:category_id" => "branches#edit_daily_dishes", as: "edit_daily_dishes"
    post "branch/menu/daily/dishes/category" => "branches#update_daily_dishes"
    get "branch/cancel/order/history(/:restaurant_id)" => "orders#cancel_orders_list", as: "cancel_orders_list"
    get "branch/admin_cancel/order/history(/:restaurant_id)" => "orders#admin_cancel_orders_list", as: "admin_cancel_orders_list"
    get "branch/dine_in/order/history(/:restaurant_id)" => "orders#dine_in_orders_list", as: "dine_in_orders_list"
    get "branch/foodclub_delivery/order/history(/:restaurant_id)" => "orders#foodclub_delivery_orders_list", as: "foodclub_delivery_orders_list"
    get "branch/foodclub_delivery/cancelled_order/history(/:restaurant_id)" => "orders#foodclub_delivery_cancelled_orders_list", as: "foodclub_delivery_cancelled_orders_list"
    get "branch/foodclub_delivery/settle/amount(/:restaurant_id)" => "orders#foodclub_delivery_settle_amount", as: "foodclub_delivery_settle_amount"
    get "branch/settle_third_party_order(/:id)" => "orders#settle_third_party_order", as: "settle_third_party_order"
    post "branch/approve_amount_settle" => "orders#approve_amount_settle", as: "approve_amount_settle"
    post "branch/manager_approve_amount_settle" => "orders#manager_approve_amount_settle", as: "manager_approve_amount_settle"
    get "branch/manager/cancel/order/history" => "orders#maneger_cancel_order_list", as: "maneger_cancel_order_list"
    get "branch/manager/admin_cancel/order/history" => "orders#maneger_admin_cancel_order_list", as: "maneger_admin_cancel_order_list"
    get "branch/manager/foodclub_delivery/order/history" => "orders#manager_foodclub_delivery_order_list", as: "manager_foodclub_delivery_order_list"
    get "branch/manager/foodclub_delivery/cancelled_order/history" => "orders#manager_foodclub_delivery_cancelled_order_list", as: "manager_foodclub_delivery_cancelled_order_list"
    get "branch/manager/foodclub_delivery/settle/amount" => "orders#manager_foodclub_delivery_settle_amount", as: "manager_foodclub_delivery_settle_amount"
    post "order/cancel" => "orders#web_order_cancel_action"
    get "branch/order/invoice/:id" => "orders#manager_order_invoice", as: "manager_order_invoice"
    get "branch/top/customer(/:restaurant_id)" => "reports#top_customer_reports", as: "top_customer_reports"
    get "top/customer/csv/list" => "reports#top_customer_reports_csv", as: "top_customer_reports_csv"
    get "branch/todays/reports(/:restaurant_id)" => "reports#todays_reports", as: "todays_reports"
    get "branch/delivery/reports(/:restaurant_id)" => "reports#delivery_reports", as: "delivery_reports"
    get "branch/settlement/reports(/:restaurant_id)" => "reports#settlement_reports", as: "settlement_reports"
    get "branch/transaction/reports(/:restaurant_id)" => "reports#transaction_reports", as: "transaction_reports"
    get "branch/review/reports(/:restaurant_id)" => "reports#review_reports", as: "review_reports"
    get "branch/points_redeemed/reports(/:restaurant_id)" => "reports#points_redeemed_reports", as: "points_redeemed_reports"
    get "branch/driver_review/reports(/:restaurant_id)" => "reports#driver_review_reports", as: "driver_review_reports"
    get "branch/driver_timing/reports(/:restaurant_id)" => "reports#driver_timing_report", as: "driver_timing_report"
    get "branch/driver_driver_timing(/:restaurant_id)" => "reports#driver_timing", as: "driver_timing"
    post "forgot/password" => "partners#business_forget_password"
    get "remove/menu/addon/category/:id" => "branches#remove_menu_addon_category"
    post "menu/category/position" => "branches#menu_category_sort"
    # get "menu/category/:category_id/:position"=>"branches#menu_category_sort"
    post "business/bank/account" => "payments#business_payment_account"
    post "/branch/status/change" => "branches#change_branch_status"
    post "/branch/image/crop" => "branches#branch_image_crop"
    get "offer/status/:offer_id" => "offers#change_offer_status", as: "change_offer_status"
    get "/card" => "payments#payment_card", as: "card_details"
    post "card/details" => "payments#add_card", as: "card_info"
    #================================End Menu =======================================
  end

  #================Api Routes==========================================
  namespace :api, defaults: { format: "json" } do
    namespace :v1 do
      get "country/list" => "countries#list"
      post "user/signup" => "registrations#create"
      post "user/login" => "sessions#create"
      post "user/social/login" => "sessions#social_auth"
      post "logout" => "sessions#logout"
      post "user/password/reset" => "sessions#forgot_password"
      post "user/otp/verification" => "sessions#otp_verification"
      post "password/reset" => "sessions#reset_password_through_token"
      post "update/profile" => "users#edit_profile"
      post "user/address" => "address#add_address"
      post "update/address" => "address#update_address"
      post "change/password" => "users#reset_password"
      post "address/list" => "address#address_list"
      post "remove/address" => "address#remove_address"
      post "view/address/details" => "address#get_address"
      post "home" => "homes#home"
      post "new/home" => "homes#new_home"
      post "coverage/area/list" => "homes#coverage_area"
      post "check/coverage/area" => "homes#check_coverage_area"
      post "create/requested/area" => "homes#create_requested_area"
      post "default/language" => "users#update_language"
      #===============Restaurants Api=============================
      post "restaurant/menu/list" => "restaurants#restaurant_branch_menu"
      post "item/addons" => "restaurants#addon_item"
      post "restaurant/menu/category/list" => "restaurants#restaurant_menu_category"
      post "restaurant/list" => "restaurants#restaurant_list"
      post "category/list" => "restaurants#category_list"
      post "party/list" => "restaurants#party_list"
      post "search/restaurants" => "restaurants#search_by_category"
      post "branch/list" => "restaurants#restaurant_branch_list"
      post "branch/make/favorite" => "restaurants#make_favorite"
      post "favorite/list" => "restaurants#favorite_list"
      #====================Cart Api ======================================
      post "add/item" => "carts#add_item_on_cart"
      post "edit/item" => "carts#edit_cart_item"
      post "cart/item/remove" => "carts#remove_cart_item"
      get "clear/cart" => "carts#clear_cart"
      get "cart/item/list" => "carts#view_cart_data"
      post "cart/items" => "carts#cart_item_list"
      post "cart/item/repeat/last" => "carts#repeat_last"
      post "cart/last/item/details" => "carts#repeat_last_data_details"
      post "cart/item/total/price" => "carts#cart_item_total_price"
      post "cart/apply/coupon" => "carts#apply_coupon"
      #===========================Home ====================================
      post "suggest/search" => "homes#suggest_search"
      post "suggest/item/search" => "homes#suggest_item_search"
      # =======================order=======================================
      post "order/new" => "orders#new_order"
      post "order/reorder" => "orders#reorder"
      post "order/list" => "orders#order_list"
      post "order/show" => "orders#show_order"
      post "order/status" => "orders#order_status"
      post "transporter/order" => "orders#transporter_order"
      # routes for business
      post "business/orders" => "orders#business_orders"
      post "business/order/action" => "orders#order_action"
      post "branch/order/view" => "orders#branch_order_view"
      post "branch/transporter" => "restaurants#add_branch_transporter"
      post "iou" => "restaurants#add_iou"
      post "update/order/status" => "orders#order_delivered"
      post "orders/graph" => "orders#orders_graph"
      # for business
      post "iou/list" => "business#iou_business_list"
      post "paid/iou" => "business#paid_iou"
      post "adds/request" => "business#adds_request"
      post "adds/show" => "business#adds_show"
      get "delete/adds/:adds_id" => "business#delete_adds"
      get "week/list" => "business#week_list"
      post "business/branches" => "business#business_branches"
      get "branch/:branch_id/areas" => "business#business_branch_areas"
      get "offers/list" => "business#offers_list"
      get "delete/offer/:offer_id" => "business#delete_offer"
      get "reload/business/restaurants" => "business#reload_business_restaurants"
      # routes for tranporters
      post "transporters/orders/list" => "orders#transporters_orders_list"
      post "tranportr/order/show" => "orders#transporter_order_show"
      post "add/order/transporter" => "orders#add_transporter_to_order"
      post "order/delivered" => "orders#order_delivered"
      post "check/items/list" => "orders#check_items_list"

      post "branch/transporter/list" => "restaurants#branch_transporter"
      get "update/status" => "transporters#transporter_status"
      post "transporter/tracking" => "transporters#transporter_tracking"
      post "iou/transporter/list" => "transporters#transpoter_iou_list"
      post "transporter/zone/list" => "transporters#zone_list"
      post "transporter/zone/area/list" => "transporters#zone_area_list"
      post "transporter/shifts/list" => "transporters#shifts_list"
      post "transporter/accept/order" => "transporters#accept_order"
      # ===========================Point===============================
      post "point/list" => "points#point_list"
      post "update/device" => "users#device_token_update"
      post "category/add" => "restaurants#add_category"
      post "upadte/category" => "restaurants#update_category"
      # =====================Rating=====================================
      post "rating" => "ratings#rating"
      #==========================Notification===========================
      post "notification/list" => "notifications#notification_list"
      get "notification/count" => "notifications#unseen_notification_count"
      post "seen/notification" => "notifications#seen_notifiction"
      # =========================Guest Session=========================================
      post "guest/token" => "guest_sessions#guest_token"
      #==========================offers=========================================
      post "offer/list" => "offers#offer_list"
      post "add/offer" => "offers#add_offer"
      post "update/order/stage" => "orders#order_update_cooked_stage"
      get  "guest/user/address" => "address#guest_user_address"
      post "offer/branch/area" => "offers#offer_branch_area"
      post "update/contact/number" => "address#update_contact_number"
      post "order/stage/update" => "orders#change_order_stage_onway"
      post "transporter/login" => "sessions#transporter_login"
      post "branch/reviews" => "restaurants#branch_reviews"

      post "club/category" => "clubes#club_category_list"
      post "clube/sub/category" => "clubes#clube_sub_category_list"
      post "user/club" => "clubes#user_club"
      get "user/details" => "sessions#user_details"
      post "user/validate" => "sessions#check_email_or_username"
      get "generate/referral" => "referrals#generate_referral"

      post "suggest/restaurant" => "homes#suggest_restaurant"
      post "web/suggest/restaurant" => "homes#web_suggest_restaurant"
      post "upload/image" => "homes#upload_image"
      post "branch/areas" => "business#branch_area"
      post "update/order/transporter" => "orders#update_transporter_in_order"
      post "points/details" => "points#branch_wise_point_details"
      post "party_points/details" => "points#party_point_details"
      post "party_points/buy" => "points#buy_party_points"

      get "order/review" => "order_reviews#review"
      post "review" => "order_reviews#order_last_review"
      get "notifications/clear" => "users#nofitication_clear"
      post "branch/menu/list" => "restaurants#branch_menu"
      post "user/password/recovery" => "sessions#password_recovery"
      post "web/user/password/recovery" => "sessions#web_password_recovery"
      post "version/control" => "referrals#app_version_check"
      post "upload/image/imagekit" => "referrals#upload_image"
      get "latest/app/version" => "referrals#latest_app_version"
      post "update/latest/app/version" => "referrals#update_latest_app_version"
      #=================================================================================
    end
  end
  # ===================Web Routes=========================================
  namespace :api, defaults: { format: "json" } do
    namespace :web do
      post "home" => "homes#home"
      post "category/list" => "restaurants#category_list"
      post "search/restaurant" => "restaurants#search_restaurant"
      post "branch/menus" => "restaurants#web_restaurant_branch_menu"
      post "categories/list" => "restaurants#web_category_list"
      post "item.addons" => "restaurants#web_addon_item"
      post "restaurant/list" => "restaurants#web_restaurant_list"
      post "web/coverage/area/list" => "homes#web_coverage_area"
      get "cart/list" => "carts#web_cart_data_list"
      get "user/details" => "users#web_user_details"
      post "remove/item" => "carts#remove_cart_item"
      post "restaurant/request" => "new_restaurant_requests#new_restaurant_request"
      post "order" => "orders#web_new_order"
      post "cart/details" => "orders#cart_details"
      post "cart/item/special/request" => "carts#add_item_special_request"
      post "validate/email" => "users#validate_email"
      post "forgot/password" => "users#web_forgot_password"
      post "enable/restaurant/list" => "homes#enable_restaurant_list"
      post "web/coverage/area/list_by_country" => "homes#web_coverage_area_by_country"
    end
  end

  namespace :customer do
    get "login" => "customers#login", as: "customer_login"
    post "customer/auth" => "customers#customer_auth", as: "customer_auth"
    get "signup" => "customers#signup", as: "customer_signup"
    post "create_customer" => "customers#create_customer", as: "create_customer"
    post "update_customer" => "customers#update_customer", as: "update_customer"
    get "logout" => "customers#logout", as: "customer_logout"
    post "forgot/password" => "customers#forgot_password"
    get "dashboard" => "customers#dashboard"
    get "point_details" => "customers#point_details"
    get "order_details" => "customers#order_details"
    get "restaurants/list" => "restaurants#list"
    get "restaurants/offer_list" => "restaurants#offer_list"
    get "restaurant/:id/details" => "restaurants#restaurant_details", as: "restaurant_details"
    post "submit_branch_rating" => "restaurants#submit_branch_rating"
    get "add_user_club" => "customers#add_user_club"
    get "new_address" => "customers#new_address"
    post "add_address" => "customers#add_address"
    get "edit_address" => "customers#edit_address"
    post "update_address" => "customers#update_address"
    get "fill_address" => "customers#fill_address"
    get "new_guest_address" => "customers#new_guest_address"
    post "add_guest_address" => "customers#add_guest_address"
    get "edit_guest_address" => "customers#edit_guest_address"
    post "update_guest_address" => "customers#update_guest_address"
    get "send_otp" => "customers#send_otp"
    post "verify_otp" => "customers#verify_otp"
    get "order_item_details" => "orders#order_item_details"
    get "add_order_item" => "orders#add_order_item"
    get "deduct_order_item" => "orders#deduct_order_item"
    get "add_addon_item" => "orders#add_addon_item"
    get "deduct_addon_item" => "orders#deduct_addon_item"
    post "add_items_to_cart" => "orders#add_items_to_cart"
    get "remove_cart_item" => "orders#remove_cart_item"
    get "cart_item_list" => "orders#cart_item_list"
    post "place_order" => "orders#place_order"
    post "mail_order_payment_link" => "orders#mail_order_payment_link"
    get "live_order_tracking" => "orders#live_order_tracking"
    get "reorder_items" => "orders#reorder_items"
    get "add_favorite_branch" => "customers#add_favorite_branch"
    get "remove_favorite_branch" => "customers#remove_favorite_branch"
    get "party_points_list" => "points#party_points_list"
    get "party_points_details" => "points#party_points_details"
    get "buy_party_points" => "points#buy_party_points"
    get "dine_in_order_details" => "orders#dine_in_order_details"
    post "place_dine_in_order" => "orders#place_dine_in_order"
  end
  # =====================End=============================================

  resources :welcome
  get "privacy/policies/:status" => "welcome#privacy_policies"
  get "graph/pdf/branch_id/:branch_id/user/:token" => "welcome#graph_pdf"
  get "about/us/:status" => "welcome#about_us"
  get "contact-us/:status" => "welcome#contact_us", as: "contact_us"
  post "contact/to/admin" => "welcome#contact_us_to_admin"
  get "user/menu_item_image_upload" => "welcome#menu_item_image_upload", as: "menu_item_image_upload"
  post "user/upload_menu_item_image" => "welcome#upload_menu_item_image", as: "upload_menu_item_image"
  get "sitemap" => "welcome#sitemap"
  get "/check_email_exist" => "users#check_email_exist"
  get "*path" => redirect("/404.html")
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
