class MessagesController < ApplicationController
  before_action :set_application
  before_action :set_chat
  before_action :set_message, only: [:show, :update, :destroy]

  # GET /applications/:application_token/chats/:chat_number/messages
  def index
    @messages = @chat.messages
    render json: @messages.map { |message| selected_attributes_for_message(message) }
  end

  # GET /applications/:application_token/chats/:chat_number/messages/:id
  def show
    render json: selected_attributes_for_message(@message)
  end

  # GET /applications/:application_token/chats/:chat_number/messages/search
  def search
    query = params[:query]
    unless query.present?
      return render json: { error: 'Query parameter is missing' }, status: :bad_request
    end

    results = Message.search_message(@chat.id, query)
    render json: results.records.map { |message| selected_attributes_for_message(message) }
  end

  # POST /applications/:application_token/chats/:chat_number/messages
  def create
    new_message_number = create_new_message(params[:body])
    render json: {  message_number: new_message_number }, status: :created
  end

  # PATCH/PUT /applications/:application_token/chats/:chat_number/messages/:id
  def update
    if @message.update(message_params)
      render json: selected_attributes_for_message(@message)
    else
      render json: @message.errors, status: :unprocessable_entity
    end
  end

  # DELETE /applications/:application_token/chats/:chat_number/messages/:id
  def destroy
    delete_message
    render json: { message: "Deleted" }
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_application
    @application = Application.find_by!(token: params[:application_token])
  end

  def set_chat
    @chat = @application.chats.find_by!(number: params[:chat_number])
  end

  def set_message
    @message = @chat.messages.find_by!(number: params[:number])
  end

  # Only allow a trusted parameter "white list" through.
  def message_params
    params.require(:message).permit(:body)
  end

  def selected_attributes_for_message(message)
    message.slice(:number, :body)
  end

  def create_new_message(message_body)
    key = "last_message_count#{@chat.id}"
    retry_count = 0
    max_retries = 5
    base_sleep_time = 0.1
    last_message_count = 0
    begin
      $redis.watch(key)
      last_message_count = $redis.get(key).to_i || @chat.messages.maximum(:number) || 0
      $redis.multi do |pipeline|
        # Increment chat count
        last_message_count += 1
  
        # Set the updated count in the transaction
        pipeline.set(key, last_message_count)
  
        # Create new Message object
        new_message = @chat.messages.build(body: message_body)
        new_message.number = last_message_count
  
        object_params = {
          'key': @chat.to_json,
          'object': new_message.to_json,
        }.to_json

  
        ObjectCreationWorker.perform_async('Message', object_params)

        pipeline.sadd?("messages_count", @chat.id)
        pipeline.set(@chat.id, 0) unless pipeline.get(@chat.id)
        pipeline.incr(@chat.id)
      end
      return last_message_count
    rescue Redis::CommandError
      # Log the error and retry
      retry_count += 1
      if retry_count < max_retries
        sleep_time = base_sleep_time * (2 ** retry_count) # Exponential backoff
        sleep(sleep_time)
        retry
      else
          raise "Failed to create new message after #{max_retries} attempts due to race conditions"
      end
    ensure
        # Ensure unwatch is called to clean up
        $redis.unwatch
    end
  end

  def delete_message
    key = "last_message_count#{@chat.id}"
    # Read the current value of the key
    last_message_count = $redis.get(key).to_i || @chat.messages.maximum(:number) || 0
    retry_count = 0
    max_retries = 5
    base_sleep_time = 0.1
    begin
      # Watch the key
      $redis.watch(key)

      $redis.multi do |pipeline|
        pipeline.sadd?("messages_count", @chat.id)
        pipeline.set(@chat.id, 0) unless pipeline.get(@chat.id)
        pipeline.decr(@chat.id)
      end
      last_message_count
      rescue Redis::CommandError
        retry_count += 1
        if retry_count < max_retries
          sleep_time = base_sleep_time * (2 ** retry_count)
          sleep(sleep_time)
          retry
        else
          raise "Failed to decrement Message count after #{max_retries} attempts due to race conditions"
        end
      ensure
        $redis.unwatch
      end
    
    @message.destroy
    @message
  end
end