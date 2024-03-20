require "canister"
require "semantic_logger"

Services = Canister.new
S = Services

require_relative "services/paths"
require_relative "services/logger"
