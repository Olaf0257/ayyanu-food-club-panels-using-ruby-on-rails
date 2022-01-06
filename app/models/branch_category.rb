class BranchCategory < ApplicationRecord
  belongs_to :category
  belongs_to :branch
end
