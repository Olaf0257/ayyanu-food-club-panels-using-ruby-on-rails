class OCRSpaceService
  def self.upload(image_url)
    params = { language: 'eng',
               isOverlayRequired: true,
               iscreatesearchablepdf: false,
               issearchablepdfhidetextlayer: false,
               url: image_url }

    headers = { apikey: Rails.application.secrets['ocr_api_key'] }

    response = RestClient.post Rails.application.secrets['ocr_space_url'], params, headers

    response.body
  end
end
