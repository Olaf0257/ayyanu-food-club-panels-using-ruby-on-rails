class RemoveVoteTypeFromReview < ActiveRecord::Migration[5.1]
  def change
    remove_column :reviews, :vote_type, :string
  end
end
