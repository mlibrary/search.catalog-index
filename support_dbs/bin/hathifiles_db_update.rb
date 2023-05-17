require_relative "../sidekiq"

date = ARGV[1] || Date.today.to_s
HathifilesDatabaseUpdate.perform_async(date)
