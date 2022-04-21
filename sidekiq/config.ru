require 'sidekiq'
require 'sidekiq/web'
use Rack::Session::Cookie, secret: ENV.fetch("SESSION_KEY"), max_age: 86400
run Sidekiq::Web 
