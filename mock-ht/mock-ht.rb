require 'sinatra'

use Rack::Auth::Basic, "Restricted Area" do |username, password|
  username == ENV.fetch("HT_USERNAME") and password == ENV.fetch("HT_PASSWORD")
end

get "/catalog/zephir_upd_20220301.json.gz" do
  logger.info("hi")
  send_file "./zephir_upd_20220301.json.gz"
end
