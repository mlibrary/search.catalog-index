require_relative '../ht_secure_data'
require 'sequel'

module HathiTrust
  module DBH
    extend HathiTrust::SecureData
    begin
      DB = Sequel.connect("jdbc:mysql://#{db_machine}/#{db_db}?user=#{db_user}&password=#{db_password}&useTimezone=true&serverTimezone=UTC", login_timeout: 2, pool_timeout: 10, max_connections: 6)
    rescue => e
      STDERR.puts e
      STDERR.puts "************************************************************"
      STDERR.puts "If you're on a machine where you can't reach the database,"
      STDERR.puts "run with environment NODB=1 to skip all db stuff"
      STDERR.puts "************************************************************"
      exit 1
    end

  end

  module DBH_overlap
    extend HathiTrust::HTOverlap
    begin
      DB = Sequel.connect("jdbc:mysql://#{db_machine}/#{db_db}?user=#{db_user}&password=#{db_password}&useTimezone=true&serverTimezone=UTC", login_timeout: 2, pool_timeout: 10, max_connections: 6)
    rescue => e
      STDERR.puts e
      STDERR.puts "************************************************************"
      STDERR.puts "If you're on a machine where you can't reach the database,"
      STDERR.puts "run with environment NODB=1 to skip all db stuff"
      STDERR.puts "************************************************************"
      exit 1
    end
  end

end

