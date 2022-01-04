require 'json'
require 'httpclient'
require_relative 'best_bets/list'
require_relative 'best_bets/term'

module BestBets
  def self.load(url)
    BestBets::List.new(JSON.parse(HTTPClient.new.get(url).body))
  end
end
