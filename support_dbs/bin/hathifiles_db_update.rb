require_relative "../lib/hathifiles_database_actions"

date_input = ARGV[1] || Date.today.to_s
HathifilesDatabaseActions::Updater.new(date: date_input).run
