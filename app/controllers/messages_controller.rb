class MessagesController < ApplicationController
    before_action :set_application
    before_action :set_chat
    before_action :set_message, only: [:show, :update, :destroy]
  
    # GET /applications/:application_token/chats/:chat_id/messages
    def index
      @messages = @chat.messages
      render json: @messages
    end
  
    # GET /applications/:application_token/chats/:chat_id/messages/:id
    def show
      render json: @message
    end
  
    # POST /applications/:application_token/chats/:chat_id/messages
    def create
      max_message_number = @chat.messages.maximum(:number) || 0
      message_number = max_message_number + 1

      message = @chat.messages.create(message_params.merge(number: message_number))
      if message.persisted?
        enqueue_update_messages_count_message
        render json: message, status: :created
      else
        render json: message.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /applications/:application_token/chats/:chat_id/messages/:id
    def update
      if @message.update(message_params)
        render json: @message
      else
        render json: @message.errors, status: :unprocessable_entity
      end
    end
  
    # DELETE /applications/:application_token/chats/:chat_id/messages/:id
    def destroy
      @message.destroy
      enqueue_update_messages_count_message
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

    def enqueue_update_messages_count_message
      UpdateMessagesCountWorker.perform_async(@chat.id)
    end

end