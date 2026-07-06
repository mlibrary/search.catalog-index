require "thor"
require "services"
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
end
