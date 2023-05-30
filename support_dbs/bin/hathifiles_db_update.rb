#!/usr/local/bin/ruby

require_relative "../sidekiq"

date = ARGV[1] || Date.today.to_s
HathifilesDatabaseUpdate.set(queue: 'support').perform_async(date)
