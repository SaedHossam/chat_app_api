require 'sidekiq/cron'
Sidekiq.configure_server do |config|
    config.redis = { url: 'redis://localhost:6379/0' }

    config.on(:startup) do
      # Schedule the job to run every minute
      Sidekiq::Cron::Job.create(name: 'UpdateDatabaseCountWorker - every minute', cron: '*/15 * * * *', class: 'UpdateDatabaseCountWorker')
    end

  end
  
  Sidekiq.configure_client do |config|
    config.redis = { url: 'redis://localhost:6379/0' }
  end
