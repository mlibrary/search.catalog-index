#!/usr/local/bin/ruby

require_relative "../sidekiq"

date = ARGV[1] || Date.new(Date.today.year, Date.today.month, 1).to_s
HathifilesDatabaseFull.set(queue: 'support').perform_async(date)
