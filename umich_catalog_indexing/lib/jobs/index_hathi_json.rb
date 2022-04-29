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
      @logger.info "fetching high level browse file"
      fetch_high_level_browse
      @logger.info "starting traject process for #{@working_file}"
      run_traject
      @logger.info "finished loading marc data from #{@working_file} into #{@solr_url}"
      #@logger.info "cleaning scratch directory"
      #clean
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
    def fetch_high_level_browse
      if should_fetch?(hlb_file) 
        HighLevelBrowse.fetch_and_save(dir: hlb_dir)
        @logger.info "updated #{hlb_file}"
      else
        @logger.info "#{hlb_file} is less than one day old. Did not update"
      end
    end
    def should_fetch?(file)
      #true when file doesn't exit or if file is older than a day
      !File.exists?(file) or 
        File.stat(file).mtime < Time.now - (60*60*24) 
    end
    def hlb_dir
      "/app/lib/translation_maps"
    end
    def hlb_file
      "#{hlb_dir}/hlb.json.gz"
    end
  end
end
