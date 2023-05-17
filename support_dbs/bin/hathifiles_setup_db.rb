require "hathifiles_database"

HathifilesDatabase.new(ENV.fetch("HATHIFILES_MYSQL_CONNECTION")).recreate_tables!
