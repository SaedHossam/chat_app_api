class Message < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  settings index: { number_of_shards: 1 } do
    mappings dynamic: false do
      indexes :body, type: :text
      indexes :chat_id, type: :keyword
    end
  end
  
  belongs_to :chat

  validates :number, presence: true, uniqueness: { scope: :chat_id }
  validates :body, presence: true

  before_validation :set_message_number, on: :create
  after_create :enqueue_update_messages_count_message

  def self.search_message(chat_id, query)
    search_definition = self.build_search_definition(chat_id, query)
    Message.search(search_definition)
  end

  private

  def set_message_number
    max_number = chat.messages.maximum(:number) || 0
    self.number = max_number + 1
  end

  def self.build_search_definition(chat_id, query)
    {
      query: {
        bool: {
          must: {
            query_string: {
              query: "*#{query}*",
              fields: ["body"]
            }
          },
          filter: {
            term: {
              chat_id: chat_id
            }
          }
        }
      }
    }
  end

  def enqueue_update_messages_count_message
    UpdateMessagesCountWorker.perform_async(chat.id)
  end
end
