require_relative "boot"

#require "rails/all"
require "rails"
require "sidekiq"

#this is documentation of what's been removed
removed = %(
  action_mailer/railtie
  action_mailbox/engine
  active_storage/engine
  action_text/engine
)

%w(
  active_record/railtie
  action_controller/railtie
  action_view/railtie
  active_job/railtie
  action_cable/engine
  rails/test_unit/railtie
).each do |railtie|
  begin
    require railtie
  rescue LoadError
  end
end

# This sidekiq middleware creates calls this api to create a new job
class JobStarted
  def call(worker, job, queue, redis_pool)
    response = Faraday.post("http://localhost:3000/api/v1/jobs", {
      job_id: job["jid"],
      arguments: job["args"].to_json,
      job_class: job["class"],
      queue: queue
    })
    yield
  end
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add JobStarted
  end
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)


module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
  end
end
