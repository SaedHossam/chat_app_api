class Message < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  settings index: { number_of_shards: 1 } do
    mappings dynamic: false do
      indexes :body, type: :text
      # Add other fields here
    end
  end
  
  belongs_to :chat

  validates :number, presence: true, uniqueness: { scope: :chat_id }
  validates :body, presence: true

  before_create :set_message_number
  
  private

  def set_message_number
    max_number = chat.messages.maximum(:number) || 0
    self.number = max_number + 1
  end

end
