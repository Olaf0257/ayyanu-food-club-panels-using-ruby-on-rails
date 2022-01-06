class CloseBranchCoverageAreas < ActiveRecord::Migration[5.2]
  def up
    BranchCoverageArea.joins(branch: :restaurant).where(is_closed: false).where.not(restaurants: { title: ["Areesh", "Bab Areesh"] }).uniq.each do |bca|
      if bca.coverage_area.area != bca.branch.city
        bca.update(is_closed: true)
      end
    end
  end

  def down
  end
end
