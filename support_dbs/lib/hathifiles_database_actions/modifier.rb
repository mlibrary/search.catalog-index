module HathifilesDatabaseActions
  class Modifier
    attr_reader :scratch_dir
    def initialize(date:, 
                   scratch_dir: "/app/scratch/#{SecureRandom.alphanumeric(8)}",
                   logger: Logger.new($stdout),
                   connection: HathifilesDatabase.new(ENV.fetch("HATHIFILES_MYSQL_CONNECTION")) )
      @date_str = Date.parse(date).strftime("%Y%m%d")
      @scratch_dir = scratch_dir
      @hathifile_url = "#{ENV.fetch("HT_HOST")}/files/hathifiles/#{hathifile}"
      @logger = logger
      @connection = connection
    end

    def run
      
      @logger.info("creating scratch directory: #{@scratch_dir}")
      Dir.mkdir(@scratch_dir) unless Dir.exist?(@scratch_dir)
      
      @logger.info("pull hathifile: #{@hathifile_url}")
      http_conn = Faraday.new do |builder|
        builder.adapter Faraday.default_adapter
      end 
      response = http_conn.get @hathifile_url
      File.open("#{@scratch_dir}/#{hathifile}", 'wb') { |f| f.write(response.body) }
   
      command
    rescue => e
      @logger.error(e.message)
    ensure
      clean
    end

    def hathifile
    end

    def command
    end

    def clean
      @logger.info("removing scratch directory")
      FileUtils.remove_dir(@scratch_dir)
    end
  end
end
