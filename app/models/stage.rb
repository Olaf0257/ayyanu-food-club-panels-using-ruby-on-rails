class Stage < ApplicationRecord
 belongs_to :created_by, class_name: 'User'
  has_many :document_uploads, dependent: :destroy
end
