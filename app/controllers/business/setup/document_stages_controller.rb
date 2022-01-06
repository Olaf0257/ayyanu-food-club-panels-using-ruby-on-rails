class Business::Setup::DocumentStagesController< ApplicationController
  before_action :authenticate_business
  layout "partner_application"
  include Business::DocumentStagesHelper

  require "roo"
  require "barby/barcode/qr_code"
  require "barby/outputter/svg_outputter"

  def index
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @document_stages = @restaurant.document_stages.order("created_at DESC")
    @account_type_list = @restaurant.account_types
    @account_type = @account_type_list.where(id: @document_stages.pluck(:account_type_id).uniq).pluck(:name, :id).sort
    @account_category_date = @account_type_list.map{|at| at.account_categories}.flatten
    @account_category =  @account_category_date.present? ? @account_category_date.uniq.pluck(:name, :id).sort : []  
    start_date = params[:start_date].to_date if params[:start_date].present?
    end_date = params[:end_date].to_date if params[:end_date].present?
    @document_stages = @document_stages.where(account_category_id: params[:account_category_id]) if params[:account_category_id].present?
    @document_stages = @document_stages.where(account_type_id: params[:account_type_id]) if params[:account_type_id].present?
    @document_stages = @document_stages.where("name LIKE ?", "%#{params[:keyword]}%") if params[:keyword].present?
    @document_stages = @document_stages.where(created_at: start_date..end_date) if params[:start_date].present? || params[:end_date].present?
  end

  def document_upload_list
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @document_stages = @restaurant.document_stages.where(show_in_list: true).order("created_at DESC")
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @account_type_list = @restaurant.account_types
    @account_type = @account_type_list.where(id: @document_stages.pluck(:account_type_id).uniq).pluck(:name, :id).sort
    @account_category_date = @account_type_list.map{|at| at.account_categories}.flatten
    @account_category =  @account_category_date.present? ? @account_category_date.uniq.pluck(:name, :id).sort : []
    start_date = params[:start_date].to_date if params[:start_date].present?
    end_date = params[:end_date].to_date if params[:end_date].present?
    @document_stages = @document_stages.where(account_category_id: params[:account_category_id]) if params[:account_category_id].present?
    @document_stages = @document_stages.where(account_type_id: params[:account_type_id]) if params[:account_type_id].present?
    @document_stages = @document_stages.where("name LIKE ? OR frequency LIKE ?", "%#{params[:keyword]}%","%#{params[:keyword]}%") if params[:keyword].present?
    @document_stages = @document_stages.where(created_at: start_date..end_date) if params[:start_date].present? || params[:end_date].present?
  end

  def new_document_upload
    @document_upload =  DocumentUpload.new
    @stage = Stage.find(params[:stage])
    @document_stage = DocumentStage.find(params[:document_stage])
  end

  def edit_document_upload
    @stage = Stage.find(params[:stage])
    @document_upload =  DocumentUpload.find(params[:id])
  end

  def update_document_upload
    @document_upload =  DocumentUpload.find(params[:id])
    @stage = Stage.find(params[:stage])
    @document_upload.status = DocumentUpload.statuses[:booked]
    if params[:document_upload].blank?
      @document_upload.save
    else
      @document_upload.update(document_upload_params)
    end
  end
   
  def show_upload_document
    @document_upload =  DocumentUpload.find(params[:id])
  end 


  def document_upload
    @document_stage =  DocumentStage.find(params[:document_stage])
    @document_upload = @document_stage.document_uploads.new(document_upload_params)

    @document_upload.stage_id = params[:stage]
    @document_upload.status = DocumentUpload.statuses[:attached]
    @document_upload.barcode_url = generate_qr_code   
    if @document_upload.save
      @document_upload.image = upload_multipart_image(document_upload_params[:image], "document_stages", find_scan_serial(@document_upload) + File.extname(document_upload_params[:image].tempfile))
      @document_upload.save
      # flash[:success] = "Created Successfully!"
    else
      # flash[:error] = @document_upload.errors.full_messages.join(", ")
    end
    redirect_to document_upload_list_business_setup_document_stages_path(restaurant_id: params[:restaurant_id], popup: true, document_stage_id: @document_stage.id, id: @document_upload.id)
  end

  def generate_qr_code
    Barby::QrCode.new(@document_upload.image, level: :q, size: 10).to_svg(margin: 0)
  end

  def new
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @document_stage = DocumentStage.new
    @stages = @restaurant.stages
    @account_type = @restaurant.account_types
    @account_category_date =  @account_type.map{|at| at.account_categories}.flatten
    @account_category =  @account_category_date.present? ? @account_category_date.uniq.sort : []
  end

   def create
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @document_stage = @restaurant.document_stages.new(document_stage_params)
    if @document_stage.save
       params[:stage_ids].each do |stage_id|
        @document_stage.initiate_document_stages.create(stage_id: stage_id)
       end
      flash[:success] = "Created Successfully!"
      redirect_to business_setup_document_stages_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @document_stage.errors.full_messages.join(", ")
    end
  end

  def edit
    @document_stage = DocumentStage.find_by(id: params[:id])
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @account_type = @restaurant.account_types
    @account_category_date =  @account_type.map{|at| at.account_categories}.flatten
    @stages = @document_stage.stages
    @account_category =  @account_category_date.present? ? @account_category_date.uniq.sort : []
    render layout: "partner_application"
  end

  def update
    @document_stage = DocumentStage.find_by(id: params[:id])
    if @document_stage.update(document_stage_params)
      if params[:stage_ids].present?
        stages = @document_stage.stages.pluck(:id)-params[:stage_ids].map(&:to_i) 
        stages.each do |stage_id|
         @InitiateDocumentStage = InitiateDocumentStage.find_by(document_stage_id: @document_stage.id, stage_id: stage_id)
         @InitiateDocumentStage.destroy
        end
        params[:stage_ids].each do |stage_id|
          @document_stage.initiate_document_stages.find_or_create_by(document_stage_id: @document_stage, stage_id: stage_id)
        end
      else
        @document_stage.initiate_document_stages.destroy_all
      end  
      flash[:success] = "Updated Successfully!"
      redirect_to business_setup_document_stages_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @document_stage.errors.full_messages.join(", ")
    end
  end

  def destroy
    @document_stage = DocumentStage.find_by(id: params[:id])
    if @document_stage.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_setup_document_stages_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] =  @document_stage.errors.full_messages.join(", ")
    end
  end

  def document_detail_list
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @document_stages = @restaurant.document_stages.where(show_in_list: true).order("created_at DESC")
    @account_type_list = @restaurant.account_types
    @account_type = @account_type_list.where(id: @document_stages.pluck(:account_type_id).uniq).pluck(:name, :id).sort
    @account_category_date = @account_type_list.map{|at| at.account_categories}.flatten
    @account_category =  @account_category_date.present? ? @account_category_date.uniq.pluck(:name, :id).sort : []
    start_date = params[:start_date].to_date if params[:start_date].present?
    end_date = params[:end_date].to_date if params[:end_date].present?
    if params["keyword"].present? || params[:account_category_id] || params[:account_type_id] || params[:frequency_id]
      @document_stages = @document_stages.where("name LIKE ? OR frequency LIKE ?", "%#{params[:keyword]}%","%#{params[:keyword]}%") if params[:keyword].present?
      @document_stages = @document_stages.where(account_category_id: params[:account_category_id]) if params[:account_category_id].present?
      @document_stages = @document_stages.where(account_type_id: params[:account_type_id]) if params[:account_type_id].present?
      @document_stages = @document_stages.where(frequency: params[:frequency]) if params[:frequency].present?
    else
      @document_stages = @restaurant.document_stages.where(show_in_list: true).order("created_at DESC")
    end
  end

  def stages
    @document_stage = DocumentStage.find_by(id: params[:id])
    @stages = @document_stage.stages
  end

  def stage_uploaded_file
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @document_stage = DocumentStage.find_by(id: params[:id])
    @stages = @document_stage.stages
    @stage = @stages.find_by_id(params[:stage_id])
    @document_uploads = @stage.document_uploads.order("created_at desc")
  end
  
  def find_account_category
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    account_type = @restaurant.account_types.where(id:params[:id]).first
    @account_categories = account_type.account_categories
    # cat_id = []
    # cat_name = []
    # @account_categorys.each do |category|
    #   cat_id << category.id
    #   cat_name << category.name
    # end
    # render json: { code:200, cat_id: cat_id,cat_name: cat_name }
  end

#   def generate_qr_code
#   #   qrcode = RQRCode::QRCode.new("http://github.com/")

#   # # NOTE: showing with default options specified explicitly
#   #   png = qrcode.as_png(
#   #     bit_depth: 1,
#   #     border_modules: 4,
#   #     color_mode: ChunkyPNG::COLOR_GRAYSCALE,
#   #     color: "black",
#   #     file: nil,
#   #     fill: "white",
#   #     module_px_size: 6,
#   #     resize_exactly_to: false,
#   #     resize_gte_to: false,
#   #     size: 120
#   #   )
#   #   IO.binwrite("/tmp/github-qrcode.png", png.to_s)

# #   barcode = Barby::Code128B.new('The noise of mankind has become too much')

# # File.open('code128b.png', 'w'){|f|
# # f.write barcode.to_png(:height => 20, :margin => 5)
# # }
#       barcode_number = "abc"
#      barcode = Barby::Code128B.new(barcode_number)
#       File.open("#{Rails.root}/public/barcodes/#{barcode_number}.png", 'wb'){ |f|
#         f.write barcode.to_png(height: 50, xdim: 2, margin: 2)
#       }

#       @image = "public/barcodes/abc.png"

#   # Barcode.create(member_id: barcode_number.to_s, barcode_image: File.open("#{Rails.root}/public/barcodes/#{barcode_number}.png"))
    
#   end


  private
 

  def document_stage_params
    params.require(:document_stage).permit(:name,:account_type_id, :account_category_id,:frequency,:show_in_list,:stage_id).merge(created_by_id: @user.id)
  end

  def document_upload_params
    params.require(:document_upload).permit(:bank_id,:date, :depositor_number,:account_name, :account_number,:note, :serial_number, :vendor_id, :emplyee_id,:employee_name,:vendor_number,:card_type_id, :number_of_machine, :deduction_type, :amounts, :exchange_name, :person_recieve_id, :name,:document_stage_id,:stage_id, :image)
  end
end
