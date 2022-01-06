class Business::KdsController < ApplicationController
	before_action :authenticate_business, except: [:change_order_color] 
	layout "partner_application"

	def dashboard
		render layout: "partner_application"
	end


	def index
		@restaurant_id =params[:restaurant_id]
    	@restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    	@branch = @restaurant.branches.first
		@kds = Kds.where(restaurant_id: params[:restaurant_id]).order("created_at desc")
	end

	def new
		@restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
		@kds = Kds.new
	end

	def edit
		@restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    	# @task_lists = @restaurant.task_lists
    	@kds = Kds.find_by(id: params[:id])
    	render layout: "partner_application"
	end

	def update
		@kds = Kds.find_by(id: params[:id])
		if @kds.update(kds_params)
			flash[:success] = "KDS Created Successfully!"
		else
			flash[:error] = @kds.errors.full_messages.join(", ")
		end
		redirect_to business_kds_path(restaurant_id: params[:kds][:restaurant_id])
	end

	def create
		@kds = Kds.new(kds_params)
		if @kds.save
			flash[:success] = "KDS Created Successfully!"
		else
			flash[:error] = @kds.errors.full_messages.join(", ")
		end
		redirect_to business_kds_path(restaurant_id: params[:kds][:restaurant_id])
	end

	def find_country_based_branch
		@task_types = []
		@restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
		@branches = @restaurant.branches.where(country: params[:country_name])
	end


	def find_branch_based_station
		@task_types = []
		@restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
		@stations = Station.where(branch_id: params[:branch_id])
	end


	def change_order_color
		transaction = PosTransaction.find_by(id: params[:transaction_id])
		color = transaction.get_color
		result = {
			color: color,
			transaction_id: params[:transaction_id].to_s
		}
		render json: result
	end


	def destroy
		@task_list = Kds.find_by(id: params[:id])
		if @task_list.destroy
			flash[:success] = "KDS Deleted Successfully!"
			redirect_to  business_task_management_restaurant_assign_tasks_path(restaurant_id: params[:restaurant_id])
		else
			flash[:error] = @task_list.errors.full_messages.join(", ")
		end
	end

	private
  
    def kds_params
      params.require(:kds).permit(:restaurant_id, :created_by_id, :name, :kds_type,:asset_type_id, :station_id , country_ids: [],branch_ids: [])
    end

end