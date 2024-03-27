require "sequel"

S.register(:no_db?) { ENV["NODB"] ? true : false }
S.register(:reindex?) { ENV["REINDEX"] ? true : false }

# Overlap DB
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
  warn "Cannot Reach #{S.overlap_host}"
  warn "If you're on a machine where you can't reach the database,"
  warn "run with environment NODB=1 to skip all db stuff"
  warn "************************************************************"
  exit 1
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

S.register(:overlap_db) do
  if ENV["APP_ENV"] == "test"
    S.overlap_memory
  else
    S.overlap_mysql
  end
end

# Hathifiles DB
S.register(:hathifiles_user) { ENV.fetch("HATHIFILE_USER", "user") }
S.register(:hathifiles_password) { ENV.fetch("HATHIFILE_PASSWORD", "password") }
S.register(:hathifiles_host) { ENV.fetch("HATHIFILE_HOST", "hathifiles") }
S.register(:hathifiles_db) { ENV.fetch("HATHIFILE_DB", "hathifiles") }

S.register(:hathifiles_mysql) do
  DB = Sequel.connect("mysql2://#{S.hathifiles_host}/#{S.hathifiles_db}?user=#{S.hathifiles_user}&password=#{S.hathifiles_password}&useTimezone=true&serverTimezone=UTC", login_timeout: 2, pool_timeout: 10, max_connections: 6)
rescue => e
  warn e
  warn "************************************************************"
  warn "Cannot Reach #{S.hathifiles_host}"
  warn "If you're on a machine where you can't reach the database,"
  warn "run with environment NODB=1 to skip all db stuff"
  warn "************************************************************"
  exit 1
end
