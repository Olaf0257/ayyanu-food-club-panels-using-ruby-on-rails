class JobOpening < ApplicationRecord
  belongs_to :country
  belongs_to :job_position

  def self.search_job_application_list(searched_department_id, searched_designation_id, keyword)
    job_applications = all.joins(:job_position)
    job_applications = job_applications.where(job_positions: {department_id: searched_department_id}) if searched_department_id.present?
    job_applications = job_applications.where(job_positions: {designation_id: searched_designation_id}) if searched_designation_id.present?
    job_applications = job_applications.where("`first_name` LIKE ? || `last_name` LIKE ?", "%#{keyword}%", "%#{keyword}%") if keyword.present?
    job_applications
  end

  def self.job_application_csv
    CSV.generate do |csv|
      header = "Job Application"
      # csv << [header]

      second_row = ["ID", "Job_Title", "Department", "Designation", "Current_Country", "Candidate_Name", "Candidate_Email", "Phone_Number", "Status", "Created_By", "Created_at"]
      csv << second_row

      all.each do |application|
        @row = []
        @row << application.id
        @row << application&.job_position&.title
        @row << application&.job_position&.department&.name&.titleize
        @row << application&.job_position&.designation&.name&.titleize
        @row << application&.country&.name&.titleize
        @row << application.first_name
        @row << application.email
        @row << application.country_code.to_s + application.phone_number
        @row << application&.status.titleize
        @row << self.created_by(application.job_position)
        @row << application.created_at
        csv << @row
      end
    end
  end

  def self.created_by(user_detail)
    user = User.find_by_id(user_detail.created_by_id)
    unless user.blank?
      if user.auths.first.role == "business" 
        user&.name
      elsif user.auths.first.role == "manager" 
        user.branch_managers.first.branch.restaurant.title
      elsif user.auths.first.role == "kitchen_manager" || user.auths.first.role == "delivery_company" || user.influencer 
        user&.name 
      end 
    end
  end
end
