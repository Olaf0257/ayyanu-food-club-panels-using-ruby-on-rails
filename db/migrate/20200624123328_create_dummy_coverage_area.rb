class CreateDummyCoverageArea < ActiveRecord::Migration[5.2]
  def up
    area = CoverageArea.new
    area.area = "No Area Present"
    area.status = "deactivate"
    area.save(validate: false)
  end

  def down
    CoverageArea.find_by(area: "No Area Present")&.destroy
  end
end
