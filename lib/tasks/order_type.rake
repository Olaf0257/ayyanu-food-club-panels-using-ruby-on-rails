namespace :order_type do
  desc "Create order type"
  task create_order_types: :environment do
    order_types = ['Dine In', 'Delivery', 'Take out', 'Catering']
    order_types.each do |type|
      OrderType.find_or_create_by(name: type, created_by_id: 809)
    end
  end


  desc "remove duplicate point entry"
  task remove_duplicate_point_entry: :environment do
    puts "------------process start----------------"
    users = User.all.select { |user| user.points.count > 1 }
    users.each do |user|
      points = user.points.where(point_type: 'Debit').group_by(&:created_at)
      points.each do |key, values|
        if values.count > 1
          values.each_with_index do |value, index|
            value.destroy if index != 0
          end
        end
      end
    end
    puts "------------process end----------------"
  end
end
