module Business::TaskManagement::TaskCategoriesHelper

  def find_branch(task_category)
    location = JSON task_category.location rescue ""
    branches = Branch.where(id: location) unless location.blank?
    branches.map(&:address).join(",") unless branches.blank?
  end

  def find_location_ids(task_category)
    location = JSON task_category.location rescue ""
    branches = Branch.where(id: location) unless location.blank?
    branches.map(&:id) unless branches.blank?
  end

  def find_location_assign_ids(task_category)
    location = task_category.branch_ids.split(",")
    branches = Branch.where(id: location.reject(&:empty?)) unless location.blank?
    branches.map(&:id) unless branches.blank?
  end

  def find_task_mgmt_branch(task_category)
    branches = Branch.where(id: task_category.location) unless task_category.location.blank?
    branches.map(&:address).join(",") unless branches.blank?
  end

  def find_task_mgmt_branch_ids(task_category)
    branches = Branch.where(id: task_category.location) unless task_category.location.blank?
    branches.map(&:id) unless branches.blank?
  end
end