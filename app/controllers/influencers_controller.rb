class InfluencersController < ApplicationController
  before_action :require_admin_logged_in

  def list
    @users = User.influencer_users.where(is_approved: 1)
    @users = @users.where(country_id: @admin.country_id) if @admin.class.name != "SuperAdmin"
    @countries = Country.where(id: @users.pluck(:country_id).uniq).pluck(:name, :id).sort
    @users = @users.filter_by_country(params[:searched_country_id]) if params[:searched_country_id].present?
    @users = @users.search_by_keyword(params[:keyword]) if params[:keyword].present?
    @users = @users.where("DATE(users.created_at) >= ?", params[:start_date]) if params[:start_date].present?
    @users = @users.where("DATE(users.created_at) <= ?", params[:end_date]) if params[:end_date].present?
    @users = @users.order_by_id_desc

    respond_to do |format|
      format.html { render layout: "admin_application" }
      format.csv { send_data @users.influencer_list_csv, filename: "influencer_list.csv" }
    end
  end

  def requested_list
    @users = User.influencer_users.where(is_approved: 0, is_rejected: 0)
    @users = @users.where(country_id: @admin.country_id) if @admin.class.name != "SuperAdmin"
    @countries = Country.where(id: @users.pluck(:country_id).uniq).pluck(:name, :id).sort
    @users = @users.filter_by_country(params[:searched_country_id]) if params[:searched_country_id].present?
    @users = @users.search_by_keyword(params[:keyword]) if params[:keyword].present?
    @users = @users.where("DATE(users.created_at) >= ?", params[:start_date]) if params[:start_date].present?
    @users = @users.where("DATE(users.created_at) <= ?", params[:end_date]) if params[:end_date].present?
    @users = @users.order_by_id_desc

    respond_to do |format|
      format.html { render layout: "admin_application" }
      format.csv { send_data @users.requested_influencer_list_csv, filename: "requested_influencer_list.csv" }
    end
  end

  def rejected_list
    @users = User.influencer_users.where(is_rejected: 1)
    @users = @users.where(country_id: @admin.country_id) if @admin.class.name != "SuperAdmin"
    @countries = Country.where(id: @users.pluck(:country_id).uniq).pluck(:name, :id).sort
    @users = @users.filter_by_country(params[:searched_country_id]) if params[:searched_country_id].present?
    @users = @users.search_by_keyword(params[:keyword]) if params[:keyword].present?
    @users = @users.where("users.rejected_at IS NOT NULL AND DATE(users.rejected_at) >= ?", params[:start_date]) if params[:start_date].present?
    @users = @users.where("users.rejected_at IS NOT NULL AND DATE(users.rejected_at) <= ?", params[:end_date]) if params[:end_date].present?
    @users = @users.order_by_id_desc

    respond_to do |format|
      format.html { render layout: "admin_application" }
      format.csv { send_data @users.rejected_influencer_list_csv, filename: "rejected_influencer_list.csv" }
    end
  end

  def new
    render layout: "admin_application"
  end

  def create
    user = User.new(name: params[:name].squish, email: params[:email].squish, country_id: params[:country_id], contact: params[:contact].squish, country_code: params[:country_code].squish, influencer: true)

    if user.save
      url = params[:image].present? ? upload_multipart_image(params[:image], "user") : nil
      user.update(image: url) if url.present?
      flash[:success] = "Influencer Created Successfully!"
      redirect_to influencer_requested_list_path
    else
      flash[:error] = user.errors.full_messages.first.to_s
      redirect_to influencer_new_path
    end
  end

  def edit
    session[:return_to] = request.referer
    @user = User.find(params[:user_id])
    render layout: "admin_application"
  end

  def update
    user = User.find(params[:user_id])

    if user.update(name: params[:name].squish, email: params[:email].squish, country_id: params[:country_id], contact: params[:contact].squish, country_code: params[:country_code].squish)
      prev_img = user.image.present? ? user.image.split("/").last : "n/a"
      url = params[:image].present? ? update_multipart_image(prev_img, params[:image], "user") : user.image
      user.update(image: url) if url.present?
      flash[:success] = "Influencer Updated Successfully!"
      redirect_to session.delete(:return_to)
    else
      flash[:error] = user.errors.full_messages.first.to_s
      redirect_to influencer_edit_path(user_id: user.id)
    end
  end

  def approve
    user = User.find(params[:user_id])
    user.update(is_approved: 1, is_rejected: 0, reject_reason: "", approved_at: Time.zone.now, rejected_at: nil)
    create_influencer_user(user)
    flash[:success] = "Influencer Approved Successfully!"
    redirect_to request.referer
  end

  def reject
    user = User.find(params[:user_id])
    user.update(is_approved: 0, is_rejected: 1, reject_reason: params[:reject_reason].to_s.strip, approved_at: nil, rejected_at: Time.zone.now)
    flash[:success] = "Influencer Rejected Successfully!"
    redirect_to request.referer
  end

  def remove
    @user = User.find(params[:user_id])

    if @user&.destroy
      flash[:success] = "Influencer Successfully Deleted!"
    else
      flash[:error] = "Cannot Delete"
    end

    redirect_to request.referer
  end

  def contracts
    @user = User.find(params[:id])

    if @user&.influencer
      @contracts = @user.influencer_contracts.order(:start_date)
    end

    render layout: "admin_application"
  end

  def add_contract
    user = User.find(params[:user_id])
    new_range = params[:start_date].to_date..params[:end_date].to_date
    contract = user.influencer_contracts.new(start_date: params[:start_date], end_date: params[:end_date])
    @overlap = InfluencerContract.overlapping_range(new_range, nil, user.id)

    if @overlap
      flash[:error] = "Contract for this date range is already present"
    elsif contract.save
      flash[:success] = "Contract Successfully Created!"
    else
      flash[:error] = contract.errors.full_messages.first.to_s
    end

    redirect_to request.referer
  end

  def update_contract
    contract = InfluencerContract.find(params[:edit_contract_id])
    new_range = params[:edit_start_date].to_date..params[:edit_end_date].to_date
    @overlap = InfluencerContract.overlapping_range(new_range, contract.id, contract.user_id)
    contract.start_date = params[:edit_start_date]
    contract.end_date = params[:edit_end_date]

    if @overlap
      flash[:error] = "Contract for this date range is already present"
    elsif contract.save
      flash[:success] = "Contract Successfully Updated!"
    else
      flash[:error] = contract.errors.full_messages.first.to_s
    end

    redirect_to request.referer
  end

  def remove_contract
    contract = InfluencerContract.find_by(id: params[:contract_id])

    if contract.present?
      contract.destroy
      send_json_response("Contract Deleted!", "success", {})
    else
      send_json_response("Contract not found", "not exist", {})
    end
  end
end
