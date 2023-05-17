require "hathifiles_database"
require "date"
require "logger"
require "fileutils"
require "securerandom"

logger = Logger.new($stdout)
date_input = ARGV[1] || Date.new(Date.today.year, Date.today.month, 1).to_s
date = Date.parse(date_input).strftime("%Y%m%d")
scratch_dir = "/app/scratch/#{SecureRandom.alphanumeric(8)}"
hathifile = "hathi_full_#{date}.txt.gz"

logger.info("creating scratch directory: #{scratch_dir}")
Dir.mkdir(scratch_dir) unless Dir.exist?(scratch_dir)

hathifile_url = "#{ENV.fetch("HT_HOST")}/files/hathifiles/#{hathifile}"
logger.info("pull hathifile: #{hathifile_url}")

system("curl", hathifile_url, "-o", "#{scratch_dir}/#{hathifile}")
connection = HathifilesDatabase.new(ENV.fetch("HATHIFILES_MYSQL_CONNECTION"))
connection.start_from_scratch("#{scratch_dir}/#{hathifile}", destination_dir: "#{scratch_dir}"

logger.info("removing scratch directory")
FileUtils.remove_dir(scratch_dir)
