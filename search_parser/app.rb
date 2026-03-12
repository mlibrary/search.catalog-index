require "sinatra/base"
require "puma"
require_relative "lib/services"

module SearchParser
end

class SearchParser::Application < Sinatra::Base
  get "/" do
    "Hello world!"
  end
end
