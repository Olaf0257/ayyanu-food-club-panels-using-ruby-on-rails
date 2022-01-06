class DocumentsController < ApplicationController
  before_action :require_admin_logged_in
  def document_list
    @documents = get_document
    render layout: "admin_application"
  end

  def restaurant_document
    @documents = get_restaurant_document(params[:restaurant_id])
    render layout: "admin_application"
  end

  def upload_doc
    doc_url = upload_doc_on_dropbox
    admin_doc = get_admin_doc(params[:admin_doc])
    if !admin_doc
      if doc_url
        p doc_url
        doc = add_new_doc(params[:admin_doc], doc_url)
        flash[:success] = "Document added successfully"
        redirect_to document_list_path
      else
        flash[:error] = "Try again!!"
        redirect_to document_list_path
      end
    else
      admin_doc.update(contract_url: doc_url)
      flash[:success] = "Document update successfully"
      redirect_to document_list_path
    end
  end

  def reject_restaurant_doc
    restaurant_doc = restaurant_document_with_id(params[:restaurant_doc_id])
    if restaurant_doc && (restaurant_doc.is_rejected == false)
      restaurant_doc.update(is_rejected: true, reject_reason: params[:reject_resion])
      begin
        RestaurantMailer.send_email_restaurant_doc_reject(restaurant_doc).deliver_now
      rescue Exception => e
      end
      flash[:success] = "Document rejected!!"
      redirect_to restaurant_document_path
    else
      flash[:error] = "Already rejected!!"
      redirect_to restaurant_document_path
    end
  end

  def approve_restaurant_doc
    restaurant_doc = restaurant_document_with_id(params[:id])
    if restaurant_doc && (restaurant_doc.is_rejected == false) && (restaurant_doc.is_approved == false)
      restaurant_doc.update(is_approved: true)
      begin
        RestaurantMailer.send_email_restaurant_doc_approved(restaurant_doc).deliver_now
      rescue Exception => e
      end
      flash[:success] = "Document approved."
      redirect_to restaurant_document_path
    else
      flash[:error] = restaurant_doc.is_rejected ? "Already rejected!!" : "Document already approved"
      redirect_to restaurant_document_path
    end
  end
end
