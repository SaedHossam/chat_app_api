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
      chat = @application.chats.create(chat_params)
      if chat.persisted?
        render json: selected_attributes_for_chat(chat), status: :created
      else
        render json: chat.errors, status: :unprocessable_entity
      end
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
      @chat.destroy
      enqueue_update_chats_count
      render json: {message: "Deleted"}
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
end
