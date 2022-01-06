class AdminDoc < ApplicationRecord
  def self.find_all_doc(page, per_page)
    paginate(page: page, per_page: per_page)
  end

  def self.create_new_doc(title, url)
    create(doc_title: title, contract_url: url)
  end
end
