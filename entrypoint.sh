#!/bin/bash
set -e

# Wait for MySQL to be ready
until nc -z db 3306; do
  echo "Waiting for MySQL to start..."
  sleep 1
done

# Wait for Redis to be ready
until nc -z redis 6379; do
  echo "Waiting for Redis to start..."
  sleep 1
done

# Wait for Elasticsearch to be ready
until nc -z elasticsearch 9200; do
  echo "Waiting for Elasticsearch to start..."
  sleep 1
done

# Run database migrations
bundle exec rake db:migrate

# Create an Elasticsearch index for the Message model
bundle exec rake elasticsearch:index_messages

# Start the Rails server
exec "$@"
