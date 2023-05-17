module HathifilesDatabaseActions
  class Updater
    def initialize(date:, 
                   scratch_dir: "/app/scratch#{SecureRandom.alphanumeric(8)}",
                   logger: Logger.new($stdout))
      date_str = Date.parse(date).strftime("%Y%m%d")
      @scratch_dir = scratch_dir
      @hathifile = "hathi_upd_#{date_str}.txt.gz"
      @hathifile_url = "#{ENV.fetch("HT_HOST")}/files/hathifiles/#{@hathifile}"
      @logger = logger
    end

    def run
      
      @logger.info("creating scratch directory: #{@scratch_dir}")
      Dir.mkdir(@scratch_dir) unless Dir.exist?(@scratch_dir)
      
      @logger.info("pull hathifile: #{@hathifile_url}")
      
      system("curl", @hathifile_url, "-o", "#{@scratch_dir}/#{@hathifile}")
      connection = HathifilesDatabase.new(ENV.fetch("HATHIFILES_MYSQL_CONNECTION"))
      connection.update_from_file "#{@scratch_dir}/#{@hathifile}"
     
      clean
    end

    def clean
      @logger.info("removing scratch directory")
      FileUtils.remove_dir(@scratch_dir)
    end
  end
end
