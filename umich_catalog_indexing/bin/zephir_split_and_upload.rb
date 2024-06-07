#!/usr/local/bin/ruby
require_relative "../lib/jobs"
require 'date'

def valid_date?( str, format="%Y-%m-%d") #yyyy-mm-dd
  Date.strptime(str,format) rescue false
end


if ARGV.empty? || !(["full","today", ].include?(ARGV[0]) || valid_date?(ARGV[0]))
  puts "Usage: zephir_split_and_upload.rb full||today||yyyy-mm-dd"
  exit(-1)
end

config = {
  full: {
    latest_file_name: Jobs::Utilities::ZephirFile.latest_monthly_full,
    target_dir: "production/zephir_full/",
    title_log: "Start preprocessing for full reindex of HT metadata"
  },
  today: {
    latest_file_name: Jobs::Utilities::ZephirFile.latest_daily_update,
    target_dir: "production/zephir_daily/",
    title_log: "Start preprocessing for daily index of HT metadata"
  }
}

if ["full","today"].include?(ARGV[0])
  kind = ARGV[0].to_sym
  zephir_file = config[kind][:latest_file_name]
  target_dir = config[kind][:target_dir]
  title_log = config[kind][:title_log] 
else
  date = Date.strptime(ARGV[0], "%Y-%m-%d")
  zephir_file = Jobs::Utilities::ZephirFile.daily_update(date)
  target_dir = config[:today][:target_dir]
  title_log = config[:today][:title_log] 
end


logger = S.logger
logger.info title_log

zephir_file_basename = zephir_file.split(".").first

tmp_dir = File.join(S.scratch_dir, "#{SecureRandom.alphanumeric(8)}")
local_file = File.join(tmp_dir, zephir_file)
prefix = File.join(tmp_dir, zephir_file_basename) + "_"

logger.info "creating scratch directory: #{tmp_dir}"
Dir.mkdir(tmp_dir) unless Dir.exist?(tmp_dir)


logger.info "fetching Zephir file" 
system("curl", "-u",
 "#{ENV.fetch("HT_USERNAME")}:#{ENV.fetch("HT_PASSWORD")}",
 "#{ENV.fetch("HT_HOST")}/catalog/#{zephir_file}", "-o",
 local_file)


S.logger.measure_info("zephir processing") do
  Jobs::ZephirProcessing.run(zephir_file: local_file, batch_size: 200, threads: 2)
end

number_of_files = `ls #{prefix}* -1 | wc -l`.to_i
logger.info "Finished splitting Zephir file #{zephir_file}. Created #{number_of_files} files"


logger.info "Uploading files to sftp server"
client = SFTP.client
(0..number_of_files - 1).each do |num|
  suffix = num.to_s.rjust(2, "0")
  filename = "#{prefix}#{suffix}.json.gz"
  client.put(filename, target_dir)
  logger.info "uploaded #{filename}"
end
logger.info "Finished uploading zephir files to SFTP server"


logger.info "cleaning up scratch directory #{tmp_dir}"
FileUtils.remove_dir(tmp_dir)
