namespace :payment_method do
  desc "Create Payment Methods"
  task create_payment_methods: :environment do
    payment_methods = ['Cash', 'Master Card', 'Visa Card']
    payment_methods.each do |type|
      PaymentMethod.find_or_create_by(name: type, created_by_id: 809)
    end
  end

end
