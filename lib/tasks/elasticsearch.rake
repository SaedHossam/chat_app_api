# lib/tasks/elasticsearch.rake
namespace :elasticsearch do
    desc 'Index existing messages into Elasticsearch'
    task index_messages: :environment do
      Message.find_each do |message|
        message.__elasticsearch__.index_document
      end
    end
  end
  