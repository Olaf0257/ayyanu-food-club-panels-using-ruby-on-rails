class PostsController < ApplicationController
  before_action :require_admin_logged_in, except: [:list]

  def index
    @posts = Post.includes(:post_category)
    @post_categories = PostCategory.where(id: @posts.pluck(:post_category_id).uniq).pluck(:name, :id).sort
    @posts = @posts.filter_by_user_type(params[:searched_user_type]) if params[:searched_user_type].present?
    @posts = @posts.filter_by_category(params[:searched_category_id]) if params[:searched_category_id].present?
    @posts = @posts.search_by_keyword(params[:keyword]) if params[:keyword].present?
    render layout: "admin_application"
  end

  def list
    user_type = if %w[business manager kitchen_manager].include?(params[:user_role])
                  2
                elsif params[:user_role] == "delivery_company"
                  3
                elsif params[:user_role] == "influencer"
                  4
                elsif params[:user_role] == "visitor"
                  5
                elsif params[:user_role] == "call_center"
                  6
                else
                  1
                end

    @posts = Post.filter_by_user_type(user_type)
    @categories = PostCategory.where(id: @posts.pluck(:post_category_id).uniq)
    @posts = @posts.filter_by_category(params[:category_id]) if params[:category_id].present?
    @posts = @posts.search_by_keyword(params[:keyword]) if params[:keyword].present?

    render layout: "blank"
  end

  def new
    @post = Post.new
    render layout: "admin_application"
  end

  def create
    @post = Post.new(post_params)

    if @post.save
      flash[:success] = "Created Successfully!"
    else
      flash[:error] = "Cannot Create"
    end

    redirect_to posts_path
  end

  def edit
    @post = Post.find(params[:id])
    render layout: "admin_application"
  end

  def update
    @post = Post.find(params[:id])

    if @post.update(post_params)
      flash[:success] = "Uptated Successfully!"
    else
      flash[:error] = "Cannot Update"
    end

    redirect_to posts_path
  end

  def show
    @post = Post.find(params[:id])
  end

  def destroy
    @post = Post.find(params[:id])

    if @post&.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = "Cannot Delete"
    end

    redirect_to posts_path
  end

  private

  def post_params
    params.require(:post).permit(:title, :body, :user_type, :post_category_id)
  end
end
