class SubscriptionsController < ApplicationController
  before_action :require_admin_logged_in, only: [:contact_list,:all_subscribe_restaurant,:subscribe_branch]

  def all_subscribe_restaurant
    # @subscribes = Subscription.joins(:restaurant).where("title Like (?)","%#{params[:keyword]}%").all.paginate(:page=>params[:page],:per_page=>params[:per_page])
    @subscribes = Subscription.filter_subscription(params[:keyword], "subscriptions.id", "DESC", params[:page], params[:per_page],@admin)
    render layout: "admin_application"
  end

  def subscribe_branch
    @subscribes = Subscription.filter_branch_subscription(params[:keyword], "subscriptions.id", "DESC", params[:page], params[:per_page],@admin)
    render layout: "admin_application"
  end

  def contact_list
    if @admin.class.name =='SuperAdmin'
      @contacts = Contact.all.paginate(page: params[:page], per_page: params[:per_page])
    else
      country_id = @admin.class.find(@admin.id)[:country_id]
      @contacts = Contact.all.where(country_id: country_id).paginate(page: params[:page], per_page: params[:per_page])
    end
    render layout: "admin_application"
    end
end
