# frozen_string_literal: true

require "high_level_browse/version"
require "high_level_browse/db"
require "uri"
require "open-uri"

module HighLevelBrowse
  SOURCE_URL = ENV["HLB_XML_ENDPOINT"] || "https://www.lib.umich.edu/browse/categories/xml.php"

  # Fetch a new version of the raw file and turn it into a db
  # @return [DB] The loaded database
  def self.fetch
    uri = URI.parse(SOURCE_URL)
    # Why on earth OpenURI::OpenRead is mixed into http but not https, I don't know
    uri.extend OpenURI::OpenRead

    xml = uri.read

    DB.new_from_xml(xml)
  rescue => e
    raise "Could not fetch xml from '#{SOURCE_URL}': #{e}"
  end

  # Fetch and save to the specified directory
  # @param [String] dir The directory where the hlb.json.gz file will end up
  # @return [DB] The fetched and saved database
  def self.fetch_and_save(dir:)
    db = fetch
    db.save(dir: dir)
    db
  end

  # Load from disk
  # @param [String] dir The directory where the hlb.json.gz file is located
  # @return [DB] The loaded database
  def self.load(dir:)
    DB.load(dir: dir)
  end
end
