S.register(:no_db?) { ENV["NODB"] ? true : false }

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
