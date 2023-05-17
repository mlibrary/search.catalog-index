require_relative "../lib/hathifiles_database_actions"

date_input = ARGV[1] || Date.new(Date.today.year, Date.today.month, 1).to_s
HathifilesDatabaseActions::Full.new(date: date_input).run
