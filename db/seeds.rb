# # This file should contain all the record creation needed to seed the database with its default values.
# # The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).


#  SuperAdmin.create(admin_name: "TecOrb Technologies", email: "company@tecorb.com",password: "tecorb@admin66")
#  #=================Category======================
#  Category.create(:title=>"Arabic",:icon=>"http://res.cloudinary.com/dllkw7sbd/image/upload/v1526286597/categories/arabic_3x.png")
#  Category.create(:title=>"Italic",:icon=>"http://res.cloudinary.com/dllkw7sbd/image/upload/v1526367323/categories/italian_3x.png")
#  Category.create(:title=>"Burger",:icon=>"https://res.cloudinary.com/dllkw7sbd/image/upload/v1526286711/categories/burger_3x.png")
#  Category.create(:title=>"Pizza",:icon=>"http://res.cloudinary.com/dllkw7sbd/image/upload/v1526367331/categories/pizza_3x.png")
#  Category.create(:title=>"Chinese",:icon=>"https://res.cloudinary.com/dllkw7sbd/image/upload/v1526286726/categories/chinese_3x.png")
#  Category.create(:title=>"Chicken",:icon=>"https://res.cloudinary.com/dllkw7sbd/image/upload/v1526286720/categories/chicken_3x.png")
#  Category.create(:title=>"fast Food",:icon=>"https://res.cloudinary.com/dllkw7sbd/image/upload/v1526286858/categories/fastrfood_3x.png")
#  Category.create(:title=>"Healthey",:icon=>"https://res.cloudinary.com/dllkw7sbd/image/upload/v1526367520/categories/healthy_3x.png")

#  ##==============================User============================================
#  user_1 = User.create(name:"test",email:"test@gmail.com",contact:"9876543234",country_code:"+91")
#  user_2 = User.create(name:"test",email:"test@gmail.com",contact:"9876543234",country_code:"+91")
#  user_3 = User.create(name:"test",email:"test@gmail.com",contact:"9876543234",country_code:"+91")
#  user_4 = User.create(name:"test",email:"test@gmail.com",contact:"9876543234",country_code:"+91")
#  user_5 = User.create(name:"test",email:"test@gmail.com",contact:"9876543234",country_code:"+91")
#  user_6 = User.create(name:"test",email:"test@gmail.com",contact:"9876543234",country_code:"+91")
#  user_7 = User.create(name:"test",email:"test@gmail.com",contact:"9876543234",country_code:"+91")
#  user_8 = User.create(name:"test",email:"test@gmail.com",contact:"9876543234",country_code:"+91")
# ##========================Restaurant=========================================
#  Restaurant.create(:title=>"Branded Restaurants",:user_id=>user_1)
#  Restaurant.create(:title=>"Hard Rock Cafe",:user_id=>user_3)
#  Restaurant.create(:title=>"Quad Cities USA Family Restaurant",:user_id=>user_4)
#  Restaurant.create(:title=>"Margaritaville",:user_id=>user_5)
#  Restaurant.create(:title=>"Seoul USA Korean Restaurant",:user_id=>user_5)
#  Restaurant.create(:title=>"Cafe USA",:user_id=>user_6)
#  Restaurant.create(:title=>"USA Family Restaurant",:user_id=>user_7)
#  Restaurant.create(:title=>"Crawfish Town USA",:user_id=>user_8)
#  Restaurant.create(:title=>"Usa-1 Pizza",:user_id=>user_1)
#  Restaurant.create(:title=>"Thai-USA",:user_id=>user_1)
# ##============================Restaurant IMAGE========================================
# Image.create(:url=>"https://res.cloudinary.com/dllkw7sbd/image/upload/v1526296231/restaurants/6b28851f300f25eaf38c1b80b2861194--sushi-vegan-vegan-food.jpg",:restaurant_id=>1)
# Image.create(:url=>"https://res.cloudinary.com/dllkw7sbd/image/upload/v1526296240/restaurants/Au_Lac_pasta.jpg",:restaurant_id=>2)
# Image.create(:url=>"https://res.cloudinary.com/dllkw7sbd/image/upload/v1526296249/restaurants/IMG_3970.jpg",:restaurant_id=>3)
# Image.create(:url=>"http://res.cloudinary.com/dllkw7sbd/image/upload/v1526296252/restaurants/IMG_5483.jpg",:restaurant_id=>4)
# Image.create(:url=>"http://res.cloudinary.com/dllkw7sbd/image/upload/v1526296252/restaurants/IMG_5483.jpg",:restaurant_id=>5)
# Image.create(:url=>"http://res.cloudinary.com/dllkw7sbd/image/upload/v1526296252/restaurants/IMG_5483.jpg",:restaurant_id=>6)
# Image.create(:url=>"http://res.cloudinary.com/dllkw7sbd/image/upload/v1526296252/restaurants/IMG_5483.jpg",:restaurant_id=>7)
# Image.create(:url=>"https://res.cloudinary.com/dllkw7sbd/image/upload/v1526296249/restaurants/IMG_3970.jpg",:restaurant_id=>8)
# Image.create(:url=>"https://res.cloudinary.com/dllkw7sbd/image/upload/v1526296249/restaurants/IMG_3970.jpg",:restaurant_id=>9)
# Image.create(:url=>"https://res.cloudinary.com/dllkw7sbd/image/upload/v1526296231/restaurants/6b28851f300f25eaf38c1b80b2861194--sushi-vegan-vegan-food.jpg",:restaurant_id=>10)

 #===========Branches=====================
#  Branch.create(address: "235 Park Ave S# 8", city: "New York", zipcode: "10003", state: "New York", country: "Us", latitude: "40.737737", longitude: "-73.987655", restaurant_id: "1", daily_timing:"10:00 AM-11:00 PM")
#  Branch.create(address: "333 Prospect St", city: "Niagara Falls", zipcode: "14303", state: "NY", country: "Us", latitude: "43.086774", longitude: "-79.064241", restaurant_id: "2", daily_timing:"9:00 AM-9:00 PM")
#  Branch.create(address: "102 E Taylor St", city: "Grant Park", zipcode: "60940", state: "NY", country: "Us", latitude: "41.240888", longitude: "-87.643680", restaurant_id: "3", daily_timing:"10:00 AM-9:30 PM")
#  Branch.create(address: "4910 22nd Ave", city: "Moline", zipcode: "61265", state: "NY", country: "Us", latitude: "41.490137", longitude: "-90.467451", restaurant_id: "4", daily_timing:"10:00 AM-10:00 PM")
#  Branch.create(address: "1 Destiny USA Dr", city: "Syracuse", zipcode: "13204", state: "NY", country: "Us", latitude: "43.069224", longitude: "-76.173755", restaurant_id: "5", daily_timing:"10:00 AM-12:00 PM")
#  Branch.create(address: "750 S Broadway Blvd", city: "Salina", zipcode: "67401", state: "KS", country: "Us", latitude: "38.825452", longitude: "-97.625508", restaurant_id: "6", daily_timing:"10:30 AM-11:00 PM")
# #==================================BrancheCategory======================================================
# BranchCategory.create(:category_id=>1,:branch_id=>1)
# BranchCategory.create(:category_id=>2,:branch_id=>1)
# BranchCategory.create(:category_id=>3,:branch_id=>1)
# BranchCategory.create(:category_id=>4,:branch_id=>1)
# BranchCategory.create(:category_id=>5,:branch_id=>1)
# BranchCategory.create(:category_id=>6,:branch_id=>1)
# BranchCategory.create(:category_id=>7,:branch_id=>1)
# BranchCategory.create(:category_id=>8,:branch_id=>1)
# BranchCategory.create(:category_id=>1,:branch_id=>2)
# BranchCategory.create(:category_id=>2,:branch_id=>2)
# BranchCategory.create(:category_id=>3,:branch_id=>2)
# BranchCategory.create(:category_id=>4,:branch_id=>2)
# BranchCategory.create(:category_id=>5,:branch_id=>2)
# BranchCategory.create(:category_id=>6,:branch_id=>2)
# BranchCategory.create(:category_id=>7,:branch_id=>2)
# BranchCategory.create(:category_id=>8,:branch_id=>2)

# BranchCategory.create(:category_id=>1,:branch_id=>3)
# BranchCategory.create(:category_id=>2,:branch_id=>3)
# BranchCategory.create(:category_id=>3,:branch_id=>3)
# BranchCategory.create(:category_id=>4,:branch_id=>3)
# BranchCategory.create(:category_id=>5,:branch_id=>3)
# BranchCategory.create(:category_id=>6,:branch_id=>3)
# BranchCategory.create(:category_id=>7,:branch_id=>3)
# BranchCategory.create(:category_id=>8,:branch_id=>3)

# Advertisement.create(:image=>"https://res.cloudinary.com/dllkw7sbd/image/upload/v1526296249/restaurants/IMG_3970.jpg",:restaurant_id=>1)
# Advertisement.create(:image=>"https://res.cloudinary.com/dllkw7sbd/image/upload/v1526296249/restaurants/IMG_3970.jpg",:restaurant_id=>2)
# Advertisement.create(:image=>"https://res.cloudinary.com/dllkw7sbd/image/upload/v1526296249/restaurants/IMG_3970.jpg",:restaurant_id=>3)

# ##===================Menu Category===============================
# MenuCategory.create(category_title: "Breakfast", branch_id: 1)
# MenuCategory.create(category_title: "Rolls", branch_id: 2)
# MenuCategory.create(category_title: "Amritsari Chole Kulche", branch_id: 3)
# MenuCategory.create(category_title: "Soups", branch_id: 4)
# MenuCategory.create(category_title: " Tandoori Starters: Non-Veg.", branch_id: 5)

# MenuCategory.create(category_title: "Shorbas", branch_id: 1)
# MenuCategory.create(category_title: "Indian Main Course: Non-Veg.", branch_id:2)
# MenuCategory.create(category_title: "Tandoori Paranthe", branch_id: 3)
# MenuCategory.create(category_title: "Breakfast", branch_id: 4)
# MenuCategory.create(category_title: "Main Course: Non-Veg. ", branch_id: 5)

# MenuCategory.create(category_title: "Snacks", branch_id: 1)
# MenuCategory.create(category_title: "Rice & Biryani ", branch_id: 2)
# MenuCategory.create(category_title: "Beverages", branch_id: 3)
# MenuCategory.create(category_title: "Rolls", branch_id: 4)
# MenuCategory.create(category_title: " Rice & Biryani ", branch_id: 5)

# MenuCategory.create(category_title: "Chinese Special", branch_id: 1)
# MenuCategory.create(category_title: "Desserts", branch_id: 2)
# MenuCategory.create(category_title: "Desserts", branch_id: 3)
# MenuCategory.create(category_title: "Snacks", branch_id: 4)
# MenuCategory.create(category_title: "Breads", branch_id: 5)

# MenuCategory.create(category_title: "Indian Starters: Veg.", branch_id: 1)
# MenuCategory.create(category_title: "Indian Main Course: Veg. ", branch_id: 2)
# MenuCategory.create(category_title: "Accompaniments", branch_id: 3)
# MenuCategory.create(category_title: "Pasta", branch_id: 4)
# MenuCategory.create(category_title: " Special Lunch ", branch_id: 5)

# ##=========================MenuItem===================

# MenuItem.create(item_name: "Bread Pakoda", item_rating: "4", price_per_item: 10, item_image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1527233760/menuItems/bread-cheese-close-up-725993.jpg", item_description: "Bread Pakoda", menu_category_id: 1)
# MenuItem.create(item_name: "Pani Puri", item_rating: "4", price_per_item: 10, item_image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1527234036/menuItems/dahi-puri.jpg", item_description: " Pani Puri ", menu_category_id: 1)
# MenuItem.create(item_name: "Vegetable Grilled Sandwich", item_rating: "4", price_per_item: 50, item_image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1527234286/menuItems/bread-breakfast-bun-461382.jpg", item_description: " Vegetable Grilled Sandwich", menu_category_id: 6)
# MenuItem.create(item_name: "Aloo Tikki Sandwich", item_rating: "4", price_per_item: 30, item_image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1527234361/menuItems/beef-blur-bread-551991.jpg", item_description: "Aloo Tikki Sandwich", menu_category_id: 6)
# MenuItem.create(item_name: "French Fries", item_rating: "4", price_per_item: 80, item_image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1527234406/menuItems/catsup-fast-food-food-115740.jpg", item_description: "French Fries", menu_category_id: 11)
# MenuItem.create(item_name: "Peanut Masala", item_rating: "4", price_per_item: 60, item_image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1527234493/menuItems/bread-creamy-food-236834.jpg", item_description: "Peanut Masala", menu_category_id: 11)
# MenuItem.create(item_name: "Veg. Spring Roll", item_rating: "4", price_per_item: 110, item_image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1527234653/menuItems/Mini_Chicken_Spring_Rolls_Soc.jpg", item_description: " Veg. Spring Roll", menu_category_id: 16)
# MenuItem.create(item_name: "Veg. Cheese Balls", item_rating: "4", price_per_item: 100, item_image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1527234692/menuItems/veg-cheese-balls.jpg", item_description: " Veg. Cheese Balls", menu_category_id: 16)
# MenuItem.create(item_name: "Broast Chicken", item_rating: "4", price_per_item: 110, item_image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1527234776/menuItems/Chicken_Broast.jpg", item_description: "Broast Chicken", menu_category_id: 21)
# MenuItem.create(item_name: "Chicken Afghani Tikka", item_rating: "4", price_per_item: 100, item_image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1527234842/menuItems/gazebocatering-1.jpg", item_description: "Chicken Afghani Tikka", menu_category_id: 21)

# MenuItem.create(item_name: "Mutton Kebab Roll", item_rating: "4", price_per_item: 10, item_image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1527234917/menuItems/mutton-kabab-sandwich.jpg", item_description: " Mutton Kebab Roll", menu_category_id: 2)
# MenuItem.create(item_name: "Veg. Paneer Roll", item_rating: "4", price_per_item: 10, item_image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1527235105/menuItems/veg-spring-roll.jpg", item_description: "Veg. Paneer Roll", menu_category_id: 2)
# MenuItem.create(item_name: "Special Cream Chicken", item_rating: "4", price_per_item: 50, item_image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1527235164/menuItems/iStock-156257590-1.jpg", item_description: "Special Cream Chicken", menu_category_id: 7)
# MenuItem.create(item_name: "Butter Chicken", item_rating: "4", price_per_item: 30, item_image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1527235268/menuItems/15cdba73dd925b63_Butter-Chicken_-_Copy.jpg", item_description: "Butter Chicken", menu_category_id: 7)
# MenuItem.create(item_name: "Chicken Biryani", item_rating: "4", price_per_item: 80, item_image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1527235321/menuItems/Best-Hyderabadi-Biryani-In-Kolkata.jpg", item_description: "Chicken Biryani", menu_category_id: 12)
# MenuItem.create(item_name: "Mutton Biryani", item_rating: "4", price_per_item: 60, item_image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1527235433/menuItems/maxresdefault.jpg", item_description: "Mutton Biryani", menu_category_id: 12)
# MenuItem.create(item_name: "Veg. Pudina Chaap", item_rating: "4", price_per_item: 110, item_image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1527235563/menuItems/13006002.jpg", item_description: "Veg. Pudina Chaap", menu_category_id: 17)
# MenuItem.create(item_name: "Veg. Achaari Chaap", item_rating: "4", price_per_item: 100, item_image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1527235744/menuItems/maxresdefault_2.jpg", item_description: "Veg. Achaari Chaap", menu_category_id: 17)
# MenuItem.create(item_name: "Shahi Paneer", item_rating: "4", price_per_item: 110, item_image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1527235768/menuItems/maxresdefault_1.jpg", item_description: "Cottage cheese cooked in a thick gravy made of cream and tomato", menu_category_id: 22)
# MenuItem.create(item_name: "Matar Paneer ", item_rating: "4", price_per_item: 100, item_image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1527235751/menuItems/Matter-panner.jpg", item_description: "Boiled green peas and cottage cheese, sautéed in a tomato gravy with spices", menu_category_id: 22)

# ##=========================MenuItem addon Category===================

#  ItemAddonCategory.create(addon_category_name: "Choose Your Bread",min_selected_quantity: 1,max_selected_quantity: 5,menu_item_id:1)
#  ItemAddonCategory.create(addon_category_name: "Your Choice Of Cheese",min_selected_quantity: 1,max_selected_quantity: 5,menu_item_id:1)
#  ItemAddonCategory.create(addon_category_name: "Your Choice Of",min_selected_quantity: 1,max_selected_quantity: 5,menu_item_id:1)
#  ItemAddonCategory.create(addon_category_name: "Your Choice Of Drink",min_selected_quantity: 1,max_selected_quantity: 5,menu_item_id:1)

# ##=========================Addon item===================
#  ItemAddon.create(addon_title:"Wheat Bread",addon_price:4,item_addon_category_id:1)
#  ItemAddon.create(addon_title:"Italian Bread",addon_price:4,item_addon_category_id:1)
#  ItemAddon.create(addon_title:"Parmesan Oregano Bread",addon_price:4,item_addon_category_id:1)
#  ItemAddon.create(addon_title:"Honey Oat Bread",addon_price:4,item_addon_category_id:1)

#  ItemAddon.create(addon_title:"American Cheese",addon_price:5,item_addon_category_id:2)
#  ItemAddon.create(addon_title:"Cheddar Cheese",addon_price:8,item_addon_category_id:2)

#  ItemAddon.create(addon_title:"Toasted",addon_price:10,item_addon_category_id:3)
#  ItemAddon.create(addon_title:"Not Toasted",addon_price:3,item_addon_category_id:3)

#  ItemAddon.create(addon_title:"Pepsi",addon_price:15,item_addon_category_id:4)
#  ItemAddon.create(addon_title:"Diet Pepsi",addon_price:20,item_addon_category_id:4)
#  ItemAddon.create(addon_title:"7 Up",addon_price:10,item_addon_category_id:4)
#  ItemAddon.create(addon_title:"Mirinda",addon_price:15,item_addon_category_id:4)
#  ItemAddon.create(addon_title:"Mountain Dew",addon_price:15,item_addon_category_id:4)
#  ItemAddon.create(addon_title:"Water",addon_price:10,item_addon_category_id:4)
#  ItemAddon.create(addon_title:"Diet 7 Up",addon_price:30,item_addon_category_id:4)


#  City.create(:city=>"Bahrain",:country=>"Bahrain")

#  [{an: "A'ali"},
# {an: "Abu Saiba"},
# {an: "Adhari - Abu-Baham"},
# {an: "Adliya"},
# {an: "Al Bahair"},
# {an: "Al Burhama"},
# {an: "Al Dair"},
# {an: "Al Eker"},
# {an: "Al Hajar"},
# {an: "Al Hoora"},
# {an: "Al Janabiyah"},
# {an: "Al Jasra"},
# {an: "Al Lawzi"},
# {an: "Al Maqsha"},
# {an: "Al Markh"},
# {an: "Al Mazrowiah"},
# {an: "Al Musalla"},
# {an: "Al Qadam"},
# {an: "Al Qalah"},
# {an: "Al Qurayyah"},
# {an: "Al Safriyah"},
# {an: "Al Sayh"},
# {an: "Alareen"},
# {an: "Alcorniche"},
# {an: "Alfateh"},
# {an: "Alghurayfah"},
# {an: "Alguful"},
# {an: "Alhajiyat"},
# {an: "Alhunayniyah"},
# {an: "AlJuffair"},
# {an: "Alnaim"},
# {an: "Alsalmaniya"},
# {an: "Alsuwayfiyah"},
# {an: "Amwaj"},
# {an: "Arad"},
# {an: "Askar"},
# {an: "Askar Alba"},
# {an: "Awali"},
# {an: "Bahrain Bay"},
# {an: "Bahrain Financial Harbour"},
# {an: "Bani Jamra"},
# {an: "Barbar"},
# {an: "Bilad Al Qadeem"},
# {an: "Bu Ashira"},
# {an: "Bu Ghazal"},
# {an: "Bu Kowarah"},
# {an: "Bu Quwah"},
# {an: "Budaiya"},
# {an: "Buri"},
# {an: "Busaiteen"},
# {an: "Daih"},
# {an: "Damistan"},
# {an: "Dar Kulaib"},
# {an: "Diplomatic Area"},
# {an: "Diraz"},
# {an: "Diyar Al Muharraq"},
# {an: "Durrat Al Bahrain"},
# {an: "East Riffa"},
# {an: "Galaly"},
# {an: "Halat Naim"},
# {an: "Halat Seltah"},
# {an: "Hamala"},
# {an: "Hidd"},
# {an: "Hidd Industrial Area"},
# {an: "Hillat Abdul Saleh"},
# {an: "Hoarat A'ali"},
# {an: "Isa Town "},
# {an: "Jannusan"},
# {an: "Jary Al Shaikh"},
# {an: "Jaww"},
# {an: "Jazaair Beach / Bilag Al Jazaair"},
# {an: "Jeblat Hebshi"},
# {an: "Jid Al Haj"},
# {an: "Jid Ali"},
# {an: "Jidhafs"},
# {an: "Jurdab"},
# {an: "Karbabad"},
# {an: "Karranah"},
# {an: "Karzakkan"},
# {an: "Khamis"},
# {an: "Ma`ameer"},
# {an: "Madinat Hamad / Hamad Town"},
# {an: "Mahooz"},
# {an: "Malkiya"},
# {an: "Manama Center"},
# {an: "Maqabah"},
# {an: "Mina Salman"},
# {an: "Muharraq"},
# {an: "Nabih Saleh"},
# {an: "North Sehla"},
# {an: "Northern city"},
# {an: "Nuwaidrat"},
# {an: "Qudaibiya"},
# {an: "Ras Rumman"},
# {an: "Reef Island"},
# {an: "Riffa Alshamali / North Riffa"},
# {an: "Riffa Views"},
# {an: "Saar"},
# {an: "Sadad"},
# {an: "Safreh"},
# {an: "Sakhir"},
# {an: "Salihiya"},
# {an: "Salmabad"},
# {an: "Samaheej"},
# {an: "Sanabis"},
# {an: "Sanad"},
# {an: "Sea Front / City Center"},
# {an: "Seef"},
# {an: "Segaya"},
# {an: "Shahrakkan"},
# {an: "Shakhurah"},
# {an: "Sitra Abu Alayash"},
# {an: "Sitra Al Hamriyah / Sitra Mall"},
# {an: "Sitra Al Kharijiya"},
# {an: "Sitra Al Qaryah"},
# {an: "Sitra Industrial Area"},
# {an: "Sitra Mahaza"},
# {an: "Sitra Murqoban"},
# {an: "Sitra Sufala"},
# {an: "Sitra Um Al Baidh "},
# {an: "Sitra Wadiyan"},
# {an: "South Sehla"},
# {an: "Tashan"},
# {an: "Tubli"},
# {an: "Umm Al Hassam"},
# {an: "Wadi AlSail"},
# {an: "West Riffa"},
# {an: "Zallaq"},
# {an: "Zayed Town"},
# {an: "Zinj"}].each do |ca|
# 	CoverageArea.create(:area=>ca[:an],:city_id=>1)
# end


# Branch.all.pluck(:address).uniq.each do |b|
#   branches = Branch.where(:address=>b)
#   branches.each do |branch|
#   	coverage = CoverageArea.find_by_area(branch.city)
#   	timing = branch.daily_timing.split('- ')
#   	BranchCoverageArea.create(:branch_id=>branch.id,:coverage_area_id=>coverage.id,:delivery_charges=>branch.delivery_charges,:minimum_amount=>branch.min_order_amount,:delivery_time=>branch.delivery_time,:daily_open_at=>timing[0],:daily_closed_at=>timing[1])
#   end
# end

# BranchCoverageArea.where(:daily_open_at=>"Open 24 hrs").each do |b|
#   b.update_attributes(:daily_open_at=>"12:00AM",:daily_closed_at=>"12:00AM")
# end

# BranchCoverageArea.where.not(:daily_closed_at=>'').each do |b|
# 	b.update_attributes(:daily_closed_at=>b.daily_closed_at.split('|').last)
# end



# MenuCategory.all.each do |cat_name|
#     name = cat_name.category_title
# 	cat_name.update(categroy_title_ar: name)
# end

# MenuItem.all.each do |item_name|
#     name = item_name.item_name
#     description = item_name.item_description
# 	item_name.update(item_name_ar: name,item_description_ar: description)
# end


# ItemAddonCategory.all.each do |add_on|
#     name = add_on.addon_category_name
# 	add_on.update(addon_category_name_ar: name)
# end


# ItemAddon.all.each do |addon|
#     name = addon.addon_title
#    addon.update(addon_title_ar: name)
# end


# (1..130).each do |i|
# 	index = i - 1
# 	cat = CoverageArea.find_by_id(i)
# 	value = ["عالي","أبو صيبع","عذاري - ابو بهام","العدلية","البحير","البرهامة","الدير","العكر","الحجر","الحورة","الجنبية","الجسرة","اللوزي","المقشع","المرخ","المزروعية","المصلى","القدم","القلعة","القرية","الصافرية","الساية","العرين","الكورنيش","الفاتح","الغريفة","القفول","الحجيات","الحنينية","الجفير","النعيم","السلمانية","السويفية","أمواج","عراد","عسكر","عسكر ألبا","عوالي","بحرين باي","المرفأ المالي","بني جمرة","باربار","البلاد القديم","بو عشيرة","بو غزال","بو كوارة","بوقوة","البديع","بوري","البسيتين","الديه","دمستان","دار كليب","المنطقة الدبلوماسية","الدراز","ديار المحرق","درة البحرين","الرفاع الشرقي","قلالي","حالة النعيم","حالة السلطة","الهملة","الحد","منطقة الحد الصناعية","حلة العبد الصالح","هورة عالي","مدينة عيسى","جنوسان","جاري الشيخ","جو","بلاج الجزائر","جبلة حبشي","جد الحاج","جد علي","جدحفص","جرداب","كرباباد","كرانة","كرزكان","الخميس","المعامير","مدينة حمد","الماحوز","المالكية","وسط المنامة","مقابة","ميناء سلمان","المحرق","النبيه صالح","السهلة الشمالية","النويدرات","القضيبية","رأس الرمان","جزيرة ريف","الرفاع الشمالي","رفاع فيوز","سار","صدد","سافرة","الصخير","الصالحية","سلماباد","مدينة سلمان","سماهيج","سنابس","سند","الواجهة البحرية / سيتي سنتر","السيف","السقية","شهركان","الشاخورة","سترة أبو العيش","سترة الحمرية / مجمع سترة","سترة الخارجية","سترة القريه","منطقة سترة الصناعية","سترة مهزة","سترة مرقوبان","سترة سفالة","سترة أم البيض","سترة واديان","السهلة الجنوبية","طشان","توبلي","ام الحصم","وادي السيل","الرفاع الغربي","الزلاق","مدينة زايد","الزنج"][index]
# 	cat.update(area_ar: value)
# end

## Aws Server Admin panel username and password

## Admin User : fc_super_@admin.com
## password: fc_admin_foodclube@2019


