class ChatsController < ApplicationController
    before_action :set_application
    before_action :set_chat, only: [:show, :update, :destroy]

    # GET /applications/:application_token/chats
    def index
      @chats = @application.chats
      render json: @chats.map { |chat| selected_attributes_for_chat(chat) }
    end
  
    # GET /applications/:application_token/chats/:number
    def show
      render json: selected_attributes_for_chat(@chat)
    end
  
    # POST /applications/:application_token/chats
    def create
      new_chat_number = create_new_chat(params[:name])
      render json: {  chat_number: new_chat_number }, status: :created
    end
  
    # PATCH/PUT /applications/:application_token/chats/:number
    def update
      if @chat.update(chat_params)
        render json: selected_attributes_for_chat(@chat)
      else
        render json: @chat.errors, status: :unprocessable_entity
      end
    end
  
    # DELETE /applications/:application_token/chats/:number
    def destroy
      delete_chat
      render json: {message: "Deleted", chat: @chat}
    end
  
    private
  
    def set_application
      @application = Application.find_by!(token: params[:application_token])
    end
  
    def set_chat
      @chat = @application.chats.find_by!(number: params[:number])
    end

    # Only allow a trusted parameter "white list" through.
    def chat_params
      params.require(:chat).permit(:name)
    end

    def selected_attributes_for_chat(chat)
      chat.slice(:number, :name, :messages_count)
    end

    def create_new_chat(name)
      # Initialize a logger
      key = "last_chat_count_#{@application.token}"
      retry_count = 0
      max_retries = 5
      base_sleep_time = 0.1
      last_chat_count = 0
      begin
        # Watch the key
        $redis.watch(key)
    
        # Read the current value of the key
        last_chat_count = $redis.get(key).to_i || @application.chats.maximum(:number) || 0

        # Perform the transaction with pipelining
        $redis.multi do |pipeline|
  
        # Increment chat count
        last_chat_count += 1
        # Set the updated count in the transaction
        pipeline.set(key, last_chat_count)
        # Create new chat object
        new_chat = @application.chats.build(name: name, messages_count: 0)
        new_chat.number = last_chat_count
    
        object_params = {
          'key': @application.to_json,
          'object': new_chat.to_json,
        }.to_json

        ObjectCreationWorker.perform_async('Chat', object_params)

        #increment counter
        pipeline.sadd?("chat_count", @application.token)
        pipeline.set(@application.token, 0) unless pipeline.get(@application.token)
        pipeline.incr(@application.token)
      end
      # Return the new chat number
      return last_chat_count
      rescue Redis::CommandError
        # Log the error and retry
        retry_count += 1
        if retry_count < max_retries
          sleep_time = base_sleep_time * (2 ** retry_count) # Exponential backoff
          sleep(sleep_time)
          retry
        else
            raise "Failed to create new chat after #{max_retries} attempts due to race conditions"
        end
      ensure
          # Ensure unwatch is called to clean up
          $redis.unwatch
      end
    end

    def delete_chat
      logger = Logger.new(STDOUT)
      key = "last_chat_count_#{@application.token}"
      # Read the current value of the key
      last_chat_count = $redis.get(key).to_i || @application.chats.maximum(:number) || 0
      retry_count = 0
      max_retries = 5
      base_sleep_time = 0.1
      begin
        # Watch the key
        $redis.watch(key)
  
        $redis.multi do |pipeline|
          pipeline.sadd?("chat_count", @application.token)
          pipeline.set(@application.token, 0) unless pipeline.get(@application.token)
          pipeline.decr(@application.token)
          logger.info("Decremented chat count for #{@application.token}")
        end
        last_chat_count
        rescue Redis::CommandError => e
          logger.error("Failed to decrement chat count: #{e.message}")
          retry_count += 1
          if retry_count < max_retries
            sleep_time = base_sleep_time * (2 ** retry_count)
            sleep(sleep_time)
            retry
          else
            raise "Failed to decrement chat count after #{max_retries} attempts due to race conditions"
          end
        ensure
          $redis.unwatch
        end
      
      @chat.destroy
      @chat
    end
end
