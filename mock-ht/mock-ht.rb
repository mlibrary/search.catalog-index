require 'sinatra'

use Rack::Auth::Basic, "Restricted Area" do |username, password|
  username == ENV.fetch("HT_USERNAME") and password == ENV.fetch("HT_PASSWORD")
end

get "/catalog/*" do
  send_file "./file.json.gz"
end
