class RolesController < ApplicationController
  before_action :require_admin_logged_in

  def roles_list
    if session[:admin_user_id]
    @roles = Role.all.order(id: "ASC").paginate(page: params[:page], per_page: params[:per_page])
    else
      @roles = Role.where.not(id:1).order(id: "ASC").paginate(page: params[:page], per_page: params[:per_page])
    end
    render layout: "admin_application"
  end

  def add_role
    role = Role.find_by(role_name: params[:name])
    if role.blank?
      @role = Role.create(role_name: params[:name])
      params[:privilege].each do |privilege|
        RolePrivilege.create(role_id: @role.id, privilege_id: privilege)
      end
      flash[:success] = "successfully created"
    else
      flash[:error] = "Already exists"
    end
    redirect_to roles_list_path
  end

  def update_role
    role = Role.find_by(id: params[:role_id])
    if role.update(role_name: params[:name])
      RolePrivilege.where(role_id: role[:id]).destroy_all
      params[:privilege].each do |privilege|
        RolePrivilege.create(role_id: role[:id], privilege_id: privilege)
      end
      flash[:success] = "successfully updated"
    else
      flash[:error] = role.errors.full_messages.first.to_s
    end
    redirect_to roles_list_path
  end

  def remove_role
    role = Role.find_by(id: params[:role_id])
    if role.present?
      role.destroy
      send_json_response("Role remove", "success", {})
    else
      send_json_response("Role", "not exist", {})
    end
  end
end
