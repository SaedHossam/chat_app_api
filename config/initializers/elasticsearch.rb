# config/initializers/elasticsearch.rb
Elasticsearch::Model.client = Elasticsearch::Client.new(url: ENV['ELASTICSEARCH_URL'])
