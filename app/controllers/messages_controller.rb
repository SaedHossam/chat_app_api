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
    message = @chat.messages.create(message_params)
    if message.persisted?
      render json: selected_attributes_for_message(message), status: :created
    else
      render json: message.errors, status: :unprocessable_entity
    end
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
    @message.destroy
    enqueue_update_messages_count_message
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
end