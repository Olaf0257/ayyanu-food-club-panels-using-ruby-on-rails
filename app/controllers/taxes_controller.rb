class TaxesController < ApplicationController
  before_action :require_admin_logged_in
  layout "admin_application"

  def index
    @taxes = Tax.includes(:country).joins(:country)
    @taxes = @taxes.where(country_id: @admin.country_id) if @admin.class.name == "User"
    @countries = Country.where(id: @taxes.pluck(:country_id).uniq).pluck(:name, :id).sort
    @taxes = @taxes.where(country_id: params[:searched_country_id]) if params[:searched_country_id].present?
    @taxes = @taxes.order("countries.name, taxes.name")

    respond_to do |format|
      format.html {}
      format.csv { send_data @taxes.tax_list_csv(params[:searched_country_id]), filename: "tax_list.csv" }
    end
  end

  def new
    @tax = Tax.new
  end

  def create
    @tax = Tax.new(tax_params)

    if @tax.save
      flash[:success] = "Created Successfully!"
      redirect_to taxes_path
    else
      flash[:error] = @tax.errors.full_messages.first.to_s
      render "new"
    end
  end

  def edit
    @tax = Tax.find(params[:id])
  end

  def update
    @tax = Tax.find(params[:id])

    if @tax.update(tax_params)
      flash[:success] = "Uptated Successfully!"
      redirect_to taxes_path
    else
      flash[:error] = @tax.errors.full_messages.first.to_s
      render "edit"
    end
  end

  def show
    @tax = Tax.find(params[:id])
  end

  def destroy
    @tax = Tax.find(params[:id])

    if @tax.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = "Cannot Delete"
    end

    redirect_to taxes_path
  end

  private

  def tax_params
    params.require(:tax).permit(:name, :percentage, :country_id)
  end
end
