require "canister"
require "semantic_logger"
require "sequel"

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

S.register(:overlap_memory) do
  db = Sequel.sqlite
  db.create_table(:overlap) do
    Bignum :oclc
    Bignum :local_id
    String :item_type
    String :access
    String :rights
  end
  db
end
S.register(:overlap_mysql) do
  Sequel.connect("mysql2://#{ENV.fetch("HATHI_OVERLAP_HOST")}/#{ENV.fetch("HATHI_OVERLAP_DB")}?user=#{ENV.fetch("HATHI_OVERLAP_USER")}&password=#{ENV.fetch("HATHI_OVERLAP_PASSWORD")}&useTimezone=true&serverTimezone=UTC",
    login_timeout: 2,
    pool_timeout: 10,
    max_connections: 6)
rescue => e
  warn e
  warn "************************************************************"
  warn "Cannot Reach #{ENV.fetch("HATHI_OVERLAP_HOST")}"
  warn "If you're on a machine where you can't reach the database,"
  warn "run with environment NODB=1 to skip all db stuff"
  warn "************************************************************"
  exit 1
end

S.register(:overlap_db) do
  if ENV["APP_ENV"] == "test"
    S.overlap_memory
  else
    S.overlap_mysql
  end
end

Services.register(:logger) do
  SemanticLogger["Catalog Indexing"]
end

SemanticLogger.add_appender(io: S.log_stream, level: :info) unless ENV["APP_ENV"] == "test"
