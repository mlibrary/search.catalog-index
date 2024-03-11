#!/usr/local/bin/ruby
require "date"
require_relative "../lib/jobs"
require "logger"
require "zinzout"

logger = S.logger
logger.info 'Start Prep for full reindex of HT metadata'

zephir_file = Jobs::Utilities::ZephirFile.latest_monthly_full
@zephir_file_basename = zephir_file.split(".").first
scratch_dir = File.join(S.project_root,"scratch", "#{SecureRandom.alphanumeric(8)}")
@scratch_dir = scratch_dir
local_file = File.join(scratch_dir, zephir_file)


logger.info "creating scratch directory: #{scratch_dir}"
Dir.mkdir(scratch_dir) unless Dir.exist?(scratch_dir)


logger.info "fetching Zephir file" 
system("curl", "-u",
 "#{ENV.fetch("HT_USERNAME")}:#{ENV.fetch("HT_PASSWORD")}",
 "#{ENV.fetch("HT_HOST")}/catalog/#{zephir_file}", "-o",
 local_file)

file_num = 0
def outfile_path(file_num)
  suffix = file_num.to_s.rjust(2, "0")
  File.join(@scratch_dir, "#{@zephir_file_basename}_#{suffix}.json.gz")
end

Zinzout.zin(local_file) do |infile|
  until infile.eof?
    counter = 1 
    lines = infile.readlines(200_000)
    Zinzout.zout(outfile_path(file_num)) do |outfile|
      lines.each do |line|
        outfile << line
      end
    end
    file_num +=1
  end
end

logger.info "Finished splitting Zephir file file. Created #{file_num} files"
logger.info "Uploading files to sftp server"
client = SFTP.client
(0..file_num).each do |num|
  client.put(outfile_path(num), "/production/zephir_full/")
end
logger.info "Finished uploading zephir files to SFTP server"
