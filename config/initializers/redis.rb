# config/initializers/redis.rb
$redis = Redis.new(host: 'redis', port: 6379, db: 0)