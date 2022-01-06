module DocumentsHelper
  def get_document
    if @admin.class.name =='SuperAdmin'
      AdminDoc.find_all_doc(params[:page], params[:per_page])
    else
         country_id = @admin.class.find(@admin.id)[:country_id]
        #AdminDoc.where(country_id: country_id).find_all_doc(params[:page], params[:per_page])
        AdminDoc.find_all_doc(params[:page], params[:per_page])
    end
  end

  def get_restaurant_document(restaurant_id)
    
    RestaurantDocument.find_restaurant_doc(params[:page], params[:per_page], restaurant_id, @admin).order(id: "DESC")
  end

  def restaurant_document_with_id(doc_id)
    RestaurantDocument.find_by(id: doc_id)
  end

  def add_new_doc(title, url, country)
    AdminDoc.create_new_doc(title, url, country)
  end

  def get_admin_doc(title)
    AdminDoc.find_by(doc_title: title)
  end
end
