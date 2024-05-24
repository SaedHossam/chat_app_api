# app/workers/update_chats_count_worker.rb
class UpdateChatsCountWorker
    include Sidekiq::Worker
  
    def perform(application_id)
      application = Application.find_by(id: application_id)
      application.update(chats_count: application.chats.count) if application
    end
  end
  