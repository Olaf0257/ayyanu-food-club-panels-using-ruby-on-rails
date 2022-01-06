module Business::DocumentStagesHelper
	def find_scan_serial(document_upload)
		serial_number = document_upload.serial_number || ""
		document_stage = DocumentStage.find_by_id(document_upload.document_stage_id)
		document_stage&.account_category.try(:name) + "_" + Date.today.strftime("%d_%m_%Y") + "_" + serial_number + document_upload&.stage.name.gsub(" ","_") + "_" + document_stage&.name
	end

	def find_scan_serial_upload(document_upload, document_stage)
		serial_number = document_upload.serial_number || ""
		document_stage = DocumentStage.find_by_id(document_upload.document_stage_id)
		document_stage&.account_category.try(:name) + "_" + Date.today.strftime("%d_%m_%Y") + "_" + serial_number + document_upload&.stage.name.gsub(" ","_") + "_" + document_stage&.name
	end
end
