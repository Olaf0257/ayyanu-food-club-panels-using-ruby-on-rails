class ReportSubscriptionsController < ApplicationController
  before_action :require_admin_logged_in

  def index
    @countries = Country.where(id: ReportSubscription.pluck(:country_id).uniq).pluck(:name, :id)
    @subscriptions = ReportSubscription.order(:country_id, :fee)
    @subscriptions = @subscriptions.filter_by_country(params[:searched_country_id]) if params[:searched_country_id].present?
    render layout: "admin_application"
  end

  def new
    @subscription = ReportSubscription.new
    render layout: "admin_application"
  end

  def create
    @subscription = ReportSubscription.new(subscription_params)

    if @subscription.save
      flash[:success] = "Created Successfully!"
    else
      flash[:error] = @subscription.errors.full_messages.first.to_s
    end

    redirect_to report_subscriptions_path
  end

  def edit
    @subscription = ReportSubscription.find(params[:id])
    render layout: "admin_application"
  end

  def update
    @subscription = ReportSubscription.find(params[:id])

    if @subscription.update(subscription_params)
      flash[:success] = "Uptated Successfully!"
    else
      flash[:error] = @subscription.errors.full_messages.first.to_s
    end

    redirect_to report_subscriptions_path
  end

  def show
    @subscription = ReportSubscription.find(params[:id])
  end

  def destroy
    @subscription = ReportSubscription.find(params[:id])

    if @subscription&.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = "Cannot Delete"
    end

    redirect_to report_subscriptions_path
  end

  private

  def subscription_params
    params.require(:report_subscription).permit(:fee, :country_id)
  end
end