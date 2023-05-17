require_relative "../sidekiq"

date_input = ARGV[1] || Date.new(Date.today.year, Date.today.month, 1).to_s
HathifilesDatabaseFull.perform_async(date: date_input)
