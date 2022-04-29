require "logger"
module Jobs
  class IndexHathiJson
    def initialize(file:, solr_url:, logger: Logger.new($stdout))
      @file = file
      @working_file = "/app/scratch/#{@file}" 
      @logger = logger
      @solr_url = solr_url
    end
    def run
      @logger.info "fetching #{@file} from #{ENV.fetch("HT_HOST")}"
      fetch_hathi
      @logger.info "starting traject process for #{@working_file}"
      run_traject
      @logger.info "finished loading marc data from #{@working_file} into #{@solr_url}"
      @logger.info "cleaning scratch directory"
      clean
      @logger.info "finished processing #{@file}"
    end
    def fetch_hathi
      system("curl","-u",
             "#{ENV.fetch("HT_USERNAME")}:#{ENV.fetch("HT_PASSWORD")}",
             "#{ENV.fetch("HT_HOST")}/catalog/#{@file}", "-o",
             @working_file
            )
    end
    def run_traject
      system( "bundle", "exec", "traject",
             "-c", "/app/readers/ndj.rb",
             "-c", "/app/writers/solr.rb",
             "-c", "/app/indexers/settings.rb",
             "-c", "/app/indexers/common.rb",
             "-c", "/app/indexers/common_ht.rb",
             "-c", "/app/indexers/subject_topic.rb",
             "-c", "/app/indexers/umich.rb",
             "-c", "/app/indexers/umich_alma.rb",
             #"-s", "log.file=#{$stdout}",
             "-u", @solr_url,
             @working_file
      )
    end
    def clean
      File.delete(@working_file)
    end
  end
end
