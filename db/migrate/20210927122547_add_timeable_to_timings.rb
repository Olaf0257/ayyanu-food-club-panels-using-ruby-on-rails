class AddTimeableToTimings < ActiveRecord::Migration[5.2]
  def change
    add_reference :timings, :timeable, polymorphic: true
  end
end
