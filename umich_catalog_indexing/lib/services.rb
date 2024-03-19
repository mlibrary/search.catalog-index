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

S.register(:no_db?) do
  ENV["NODB"] ? true : false
end

S.register(:reindex?) do
  ENV["REINDEX"] ? true : false
end

S.register(:hathifiles_user) { ENV.fetch("HATHIFILE_USER", "user") }
S.register(:hathifiles_password) { ENV.fetch("HATHIFILE_PASSWORD", "password") }
S.register(:hathifiles_host) { ENV.fetch("HATHIFILE_HOST", "hathifiles") }
S.register(:hathifiles_db) { ENV.fetch("HATHIFILE_DB", "hathifiles") }

S.register(:hathifiles_mysql) do
  DB = Sequel.connect("mysql2://#{S.hathifiles_host}/#{S.hathifiles_db}?user=#{S.hathifiles_user}&password=#{S.hathifiles_password}&useTimezone=true&serverTimezone=UTC", login_timeout: 2, pool_timeout: 10, max_connections: 6)
rescue => e
  warn e
  warn "************************************************************"
  warn "Cannot Reach #{ENV.fetch("HATHIFILE_HOST")}"
  warn "If you're on a machine where you can't reach the database,"
  warn "run with environment NODB=1 to skip all db stuff"
  warn "************************************************************"
  exit 1
end
S.register(:hathifiles_nodb) do
  require_relative "ht_traject/no_db_mocks/ht_hathifiles"
  HathiTrust::NoDB::HathiFiles
end

S.register(:hathifiles) do
  require_relative "ht_traject/ht_hathifiles"
  HathiTrust::HathiFiles
end
S.register(:hathifiles_klass) do
  S.no_db? ? S.hathifiles_nodb : S.hathifiles
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
S.register(:overlap_user) { ENV.fetch("HATHI_OVERLAP_USER", "user") }
S.register(:overlap_password) { ENV.fetch("HATHI_OVERLAP_PASSWORD", "password") }
S.register(:overlap_host) { ENV.fetch("HATHI_OVERLAP_HOST", "hathioverlap") }
S.register(:overlap_db_name) { ENV.fetch("HATHI_OVERLAP_DB", "overlap") }

S.register(:overlap_mysql) do
  Sequel.connect("mysql2://#{S.overlap_host}/#{S.overlap_db_name}?user=#{S.overlap_user}&password=#{S.overlap_password}&useTimezone=true&serverTimezone=UTC",
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

S.register(:overlap_nodb) do
  require "ht_traject/no_db_mocks/ht_overlap"
  HathiTrust::NoDB::UmichOverlap
end

S.register(:overlap) do
  require "ht_traject/ht_overlap"
  HathiTrust::UmichOverlap
end

S.register(:overlap_klass) do
  (S.no_db? || S.reindex?) ? S.overlap_nodb : S.overlap
end

# SFTP
Services.register(:sftp_user) { ENV.fetch("ALMA_FILES_USER", "alma") }
Services.register(:sftp_host) { ENV.fetch("ALMA_FILES_HOST", "sftp") }
Services.register(:ssh_key_path) { ENV.fetch("SSH_KEY_PATH", "/etc/secret-volume/id_rsa") }

# Logger
Services.register(:logger) do
  SemanticLogger["Catalog Indexing"]
end

SemanticLogger.add_appender(io: S.log_stream, level: :info) unless ENV["APP_ENV"] == "test"
