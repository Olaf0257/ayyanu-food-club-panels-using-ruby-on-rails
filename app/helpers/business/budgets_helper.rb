module Business::BudgetsHelper
  def get_budget_list(_branches)
    Budget.all.order("id DESC").paginate(page: params[:page], per_page: params[:per_page])
  end

  def add_new_budget(branch, amount, start_date, end_date)
    Budget.crete_new_budget(branch, amount, start_date, end_date)
  end
end
