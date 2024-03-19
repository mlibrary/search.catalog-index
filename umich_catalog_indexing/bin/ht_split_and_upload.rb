#!/usr/local/bin/ruby
require "date"
require_relative "../lib/config/sftp_config"
require_relative "../lib/jobs"
require "logger"

logger = S.logger
logger.info 'Start Prep for full reindex of HT metadata'

zephir_file = Jobs::Utilities::ZephirFile.latest_monthly_full
zephir_file_basename = zephir_file.split(".").first
scratch_dir = File.join(S.project_root,"scratch", "#{SecureRandom.alphanumeric(8)}")
local_file = File.join(scratch_dir, zephir_file)
prefix = File.join(scratch_dir, zephir_file_basename) + "_"

logger.info "creating scratch directory: #{scratch_dir}"
Dir.mkdir(scratch_dir) unless Dir.exist?(scratch_dir)


logger.info "fetching Zephir file" 
system("curl", "-u",
 "#{ENV.fetch("HT_USERNAME")}:#{ENV.fetch("HT_PASSWORD")}",
 "#{ENV.fetch("HT_HOST")}/catalog/#{zephir_file}", "-o",
 local_file)


S.logger.measure_info("zephir processing") do
  Jobs::ZephirProcessing.run(full_zephir_file: local_file, batch_size: 200, threads: 2)
end

number_of_files = `ls #{prefix}* -1 | wc -l`.to_i
logger.info "Finished splitting Zephir file #{zephir_file}. Created #{number_of_files} files"
logger.info "Uploading files to sftp server"
client = SFTP.client
(0..number_of_files - 1).each do |num|
  suffix = num.to_s.rjust(2, "0")
  filename = "#{prefix}#{suffix}.json.gz"
  client.put(filename, "production/zephir_full/")
  logger.info "uploaded #{filename}"
end
logger.info "Finished uploading zephir files to SFTP server"
logger.info "cleaning up scratch directory"
FileUtils.remove_dir(scratch_dir)
