require "canister"
require "semantic_logger"

Services = Canister.new
S = Services
S.register(:marc_record_batch_size) { ENV.fetch("MARC_RECORD_BATCH_SIZE", 200_000) }

S.register(:project_root) do
  File.absolute_path(File.join(__dir__, ".."))
end

S.register(:scratch_dir) { File.join(S.project_root, "scratch") }

S.register(:log_stream) do
  $stdout.sync = true
  $stdout
end

Services.register(:logger) do
  SemanticLogger["Catalog Indexing"]
end

SemanticLogger.add_appender(io: S.log_stream, level: :info) unless ENV["APP_ENV"] == "test"
