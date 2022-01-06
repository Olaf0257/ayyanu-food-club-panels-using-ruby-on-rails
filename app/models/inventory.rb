class Inventory < ApplicationRecord
  belongs_to :article
  belongs_to :user
  belongs_to :restaurant
  belongs_to :receive_article
  belongs_to :inventoryable, polymorphic: true

  def self.search(condition)
    where("articles.name like ?", "#{condition}%")
  end

  def self.to_csv(inventories)
    attributes = ['Article', 'Over Group', 'Major Group', 'Item Group', 'ACT SOH', 'Base Unit', 'Purchase Price']

    CSV.generate(headers: true) do |csv|
      csv << attributes

      inventories.each do |category, group|
        csv << [group.last.article.try(:name), group.last.article.try(:over_group).try(:name), group.last.article.try(:major_group).try(:name), group.last.article.try(:item_group).try(:name), group.pluck(:stock).sum, group.last.article.try(:base_unit_name), ApplicationController.helpers.number_with_precision(group.last.article.try(:purchase_price), precision: 3) || 0.000]
      end
    end
  end

end
