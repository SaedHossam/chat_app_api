class ChatsController < ApplicationController
    before_action :set_application
    before_action :set_chat, only: [:show, :update, :destroy]
  
    # GET /applications/:application_token/chats
    def index
      @chats = @application.chats
      render json: @chats.map { |chat| { number: chat.number } }
    end
  
    # GET /applications/:application_token/chats/:number
    def show
      render json: { number: @chat.number }
    end
  
    # POST /applications/:application_token/chats
    def create
      max_chat_number = @application.chats.maximum(:number) || 0
      chat_number = max_chat_number + 1
    
      chat = @application.chats.create(chat_params.merge(number: chat_number))

      if chat.persisted?
        enqueue_update_chats_count
        render json: chat, status: :created
      else
        render json: chat.errors, status: :unprocessable_entity
      end
    end
  
    # PATCH/PUT /applications/:application_token/chats/:number
    def update
      if @chat.update(chat_params)
        render json: @chat
      else
        render json: @chat.errors, status: :unprocessable_entity
      end
    end
  
    # DELETE /applications/:application_token/chats/:number
    def destroy
      enqueue_update_chats_count
      @chat.destroy
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

    def enqueue_update_chats_count
      UpdateChatsCountWorker.perform_async(@application.id)
    end
end
