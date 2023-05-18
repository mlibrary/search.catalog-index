#!/usr/local/bin/ruby

require_relative "../lib/hathifiles_database_actions"

date_input = ARGV[0] || Date.today.to_s
start_date = Date.parse(date_input)

start_date.upto(Date.today) do |date|
  HathifilesDatabaseActions::Updater.new(date: date.to_s).run
end
