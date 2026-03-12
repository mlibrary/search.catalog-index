require "canister"
require "semantic_logger"

Services = Canister.new

S = Services

S.register(:app_env) { ENV["APP_ENV"] || "development" }
S.register(:app_name) { ENV["APP_NAME"] || "search_parser" }

S.register(:log_stream) do
  $stdout.sync = true
  $stdout
end

S.register(:logger) do
  SemanticLogger[S.app_name]
end

S.register(:log_level) do
  ENV["DEBUG"] ? :debug : :info
end

SemanticLogger.default_level = S.log_level

class ProductionFormatter < SemanticLogger::Formatters::Json
  # Leave out the pid
  def pid
  end

  # Leave out the timestamp
  def time
  end

  # Leave out environment
  def environment
  end

  # Leave out application (This would be Semantic Logger, which isn't helpful)
  def application
  end
end

if S.app_env != "test"
  if $stdin.tty?
    SemanticLogger.add_appender(io: S.log_stream, formatter: :color)
  else
    SemanticLogger.add_appender(io: S.log_stream, formatter: ProductionFormatter.new)
  end
end
