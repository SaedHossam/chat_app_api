class ObjectCreationWorker
    include Sidekiq::Worker
  
    def perform(modelName, record)
        model = modelName.constantize
        object = JSON.parse(record)
        puts "Creating #{modelName} #{record}"
        ActiveRecord::Base.transaction do
            model.new(JSON.parse(object['object'])).save!
            $redis.del(object['key'])
        end
    end

  end