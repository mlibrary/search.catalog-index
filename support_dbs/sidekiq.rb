require "sidekiq"
require_relative "./lib/hathifiles_database_actions"

class HathifilesDatabaseUpdate
  include Sidekiq::Worker
  def perform(date)
    HathifilesDatabaseActions::Updater.new(date: date).run
  end
end

class HathifilesDatabaseFull
  include Sidekiq::Worker
  def perform(date)
    HathifilesDatabaseActions::Full.new(date: date).run
  end
end
