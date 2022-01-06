class UpdateAdvertisementBanners < ActiveRecord::Migration[5.1]
  def up
    Advertisement.find(1).update(image: "https://ik.imagekit.io/sodhemlpr/admin/Banners-01_SHeBZxPgW.png")
    Advertisement.find(2).update(image: "https://ik.imagekit.io/sodhemlpr/admin/Banners-02_-6Oqwi-YyU.png")
    Advertisement.find(3).update(image: "https://ik.imagekit.io/sodhemlpr/admin/Banners-03_w6bW1QXbS.png")
  end

  def down
    Advertisement.find(1).update(image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1569908449/advertisement/10_-reward0.png")
    Advertisement.find(2).update(image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1569908449/advertisement/refer-friend-20.png")
    Advertisement.find(3).update(image: "https://res.cloudinary.com/dllkw7sbd/image/upload/v1569908449/advertisement/5_-off-20.png")
  end
end
