class PostCategoriesController < ApplicationController
  before_action :require_admin_logged_in

  def index
    @post_categories = PostCategory.all
    render layout: "admin_application"
  end

  def new
    @post_category = PostCategory.new
    render layout: "admin_application"
  end

  def create
    @post_category = PostCategory.new(post_category_params)

    if @post_category.save
      flash[:success] = "Created Successfully!"
      redirect_to post_categories_path
    else
      flash[:error] = @post_category.errors.full_messages.first.to_s
      redirect_to new_post_category_path
    end
  end

  def edit
    @post_category = PostCategory.find(params[:id])
    render layout: "admin_application"
  end

  def update
    @post_category = PostCategory.find(params[:id])

    if @post_category.update(post_category_params)
      flash[:success] = "Uptated Successfully!"
      redirect_to post_categories_path
    else
      flash[:error] = @post_category.errors.full_messages.first.to_s
      redirect_to edit_post_category_path(@post_category)
    end
  end

  def show
    @post_category = PostCategory.find(params[:id])
  end

  def destroy
    @post_category = PostCategory.find(params[:id])

    if @post_category&.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = "Cannot Delete"
    end

    redirect_to post_categories_path
  end

  private

  def post_category_params
    params.require(:post_category).permit(:name)
  end
end
