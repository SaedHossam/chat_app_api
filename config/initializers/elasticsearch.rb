# config/initializers/elasticsearch.rb
Elasticsearch::Model.client = Elasticsearch::Client.new(url: 'http://localhost:9200', log: true)

# Create the index with the necessary mapping
client = Elasticsearch::Model.client

unless client.indices.exists?(index: 'messages')
  client.indices.create(
    index: 'messages',
    body: {
      settings: {
        index: {
          number_of_shards: 1,
          number_of_replicas: 0
        }
      },
      mappings: {
        properties: {
          body: { type: 'text' },
          chat_id: { type: 'keyword'}
        }
      }
    }
  )
end