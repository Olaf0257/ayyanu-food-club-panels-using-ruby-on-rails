class DocumentUpload < ApplicationRecord
 # mount_uploader :image, DocumentUploader
 enum status: { attached: 0, booked: 1 }
 belongs_to :stage, optional: true
 belongs_to :vendor, optional: true
 belongs_to :bank, optional: true
end
