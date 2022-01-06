module Imagescaler
	def img_thumb imageUrl,image_width
		begin
			if imageUrl.include?("cloudinary.com")
        		imgParts = imageUrl.split("image/upload/")
       			imageUrl = "#{imgParts[0]}w_#{image_width.to_i>0 ? image_width : '300'},c_scale/#{imgParts[1]}" 
		    elsif imageUrl.include?("ik.imagekit.io")
		    	imgParts = imageUrl.split("sodhemlpr")
		    	imageUrl = "#{imgParts[0]}#{"sodhemlpr/"}tr:w-#{image_width.to_i>0 ? image_width : '300'},tr:h-#{image_width.to_i>0 ? image_width : '300'}#{imgParts[1]}"
		    end
    		imageUrl
		end
		rescue Exception => e			
		end		
end