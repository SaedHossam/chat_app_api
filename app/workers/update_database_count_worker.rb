class UpdateDatabaseCountWorker
  include Sidekiq::Worker
  require 'logger'


  def perform(*args)
    logger = Logger.new(STDOUT)
    puts 'Starting count job'
  
    # Process 'chats_count'
    puts $redis.smembers('chat_count')
    app_tokens = $redis.smembers('chat_count')
    
    app_tokens.each do |token|
      $redis.watch(token) do
        logger.info("token: #{token}")
        curr = Application.find_by(token: token)
        
        if curr
          logger.info("Token from App: #{curr.token}")
          stored_value = $redis.get(token).to_i
          new_value = (curr.chats_count || 0)  + stored_value
          logger.info("changing chat count for #{curr.token}: new value = #{new_value}")
          $redis.multi do
            $redis.set(token, 0)
            curr.update(chats_count: new_value)
          end
        else
          logger.info("App not found")
        end
  
        $redis.srem('chat_count', token)
      end
    end
  
    # Process 'messages_count'
    puts 'Updating messages'
    puts $redis.smembers('messages_count')
    chat_ids = $redis.smembers('messages_count')
  
    chat_ids.each do |chat_id|
      $redis.watch(chat_id) do
        curr_chat = Chat.find_by(id: chat_id)
  
        if curr_chat
          stored_value = $redis.get(chat_id).to_i
          new_value = stored_value # Assuming it's a direct replacement in this case
  
          $redis.multi do
            $redis.set(chat_id, 0)
            curr_chat.update(messages_count: new_value)
          end
        end
  
        $redis.srem('messages_count', chat_id)
      end
    end
  end
  
end
