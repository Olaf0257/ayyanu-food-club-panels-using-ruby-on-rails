class DocumentStage < ApplicationRecord
	FREQUENCY = [['Everyday', '1day'], ['Weekly', '1week'], ['Monthly', '1month'], ['Yearly', '1year']]
	has_many :initiate_document_stages
	has_many :stages, through: :initiate_document_stages
	has_many :document_uploads
	belongs_to :account_type, optional: true
	belongs_to :account_category , optional: true
	belongs_to :created_by, class_name: 'User'
	before_validation :set_visibility, on: :create
	after_commit :set_visiblity_update_worker

  def set_visibility
  	self.show_in_list = frequency.eql?('1day')
  end

  def set_visiblity_update_worker
  	Sidekiq.set_schedule("#{name} - #{id}", { 'every' => [frequency], 'class' => 'VisibilityUpdateWorker', 'args' => self.id })
  end
end
