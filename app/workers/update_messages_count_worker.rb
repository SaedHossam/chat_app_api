# app/workers/update_messages_count_worker.rb
class UpdateMessagesCountWorker
    include Sidekiq::Worker
  
    def perform(chat_id)
      chat = Chat.find_by(id: chat_id)
      chat.update(messages_count: chat.messages.count) if chat
    end
  end
  