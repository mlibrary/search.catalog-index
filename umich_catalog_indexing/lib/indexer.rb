require "thor"
require "services"
require "sidekiq_jobs"
require "indexer/monthly"
require "indexer/filter_zephir"
require "indexer/index_latest"

module Indexer
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "index_a_file METADATA_FILE_PATH", "produces flat file output from traject"
    option :reader, aliases: ["r"], desc: "what kind of reader should be used", enum: ["xml", "json"], default: "xml"
    option :writer, aliases: ["w"], desc: "what kind of writer should be used", enum: ["debug", "json", "null", "solr"], default: "debug"
    def index_a_file(metadata_file_path)
      config = [
        "indexers/settings.rb",
        "indexers/common.rb",
        "indexers/common_ht.rb",
        "indexers/subject_topic.rb",
        "indexers/umich.rb",
        "indexers/umich_alma.rb",
        "indexers/callnumbers.rb"
      ]
      config.prepend("/readers/#{options[:reader]}.rb")
      config.prepend("/writers/#{options[:writer]}.rb")

      config_options = config.map do |x|
        path = File.join(S.project_root, x)
        "-c #{path}"
      end.join(" ")

      `bundle exec traject #{config_options} #{metadata_file_path}`
    end

    desc "monthly SOURCE", "looks up the latest full metadata files and queues them up for the reindex solr"
    def monthly(source)
      check_source(source)
      Indexer::Monthly.public_send(source)
    end

    desc "filter_zephir full||today||yyyy-mm-dd", "Filter zephir metadata for umich public domain that's not in alma."
    def filter_zephir(date)
      unless ["full", "today"].include?(date)
        date = Date.parse(date)
      end

      fz = Indexer::FilterZephir
      config = case date
      when "full"
        fz.full_config
      when "today"
        fz.today_config
      else
        fz.date_config(date)
      end
      fz.run(**config)
    end
  end

  def index_latest(source)
    check_source(source)
    Indexer::IndexLatest.public_send(source)
  end

  private

  def check_source(source)
    raise Thor::Error, "Error: argument must be alma or zephir" unless ["alma", "zephir"].include?(source)
  end
end
