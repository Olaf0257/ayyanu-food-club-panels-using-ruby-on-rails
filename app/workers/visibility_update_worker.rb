class VisibilityUpdateWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(document_id)
    puts "=========Time.now"
    DocumentStage.find_by(id: document_id).update(show_in_list: true)
  end
end
