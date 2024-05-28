class UpdateDatabaseCountWorker
  include Sidekiq::Worker

  def perform(*args) 
    # Process 'chats_count'
    app_tokens = $redis.smembers('chat_count')
    app_tokens.each do |token|
      $redis.watch(token) do
        curr = Application.find_by(token: token)
        if curr
          stored_value = $redis.get(token).to_i
          new_value = (curr.chats_count || 0)  + stored_value
          $redis.multi do
            $redis.set(token, 0)
            curr.update(chats_count: new_value)
          end
        end
        $redis.srem('chat_count', token)
      end
    end
  
    # Process 'messages_count'
    chat_ids = $redis.smembers('messages_count')
    chat_ids.each do |chat_id|
      $redis.watch(chat_id) do
        curr_chat = Chat.find_by(id: chat_id)
        if curr_chat  
          stored_value = $redis.get(chat_id).to_i
          new_value = (curr_chat.messages_count || 0)  + stored_value
          $redis.multi do |pipeline|
            pipeline.set(chat_id, 0)
            curr_chat.update(messages_count: new_value)
          end
        end
        $redis.srem('messages_count', chat_id)
      end
    end
  end
end
