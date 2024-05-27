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

  def self.search_message(chat_id, query)
    search_definition = self.build_search_definition(chat_id, query)
    Message.search(search_definition)
  end

  private

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

end
