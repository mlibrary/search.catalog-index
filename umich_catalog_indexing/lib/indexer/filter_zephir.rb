require "tmpdir"
module Indexer
  module FilterZephir
    def self.full_config
      {
        zephir_file: Jobs::Utilities::ZephirFile.latest_monthly_full,
        target_dir: "production/zephir_full/",
        title_log: "Start preprocessing for full reindex of HT metadata"
      }
    end

    def self.today_config
      {
        zephir_file: Jobs::Utilities::ZephirFile.latest_daily_update,
        target_dir: "production/zephir_daily/",
        title_log: "Start preprocessing for daily index of HT metadata"
      }
    end

    def self.date_config(date)
      zephir_file = Jobs::Utilities::ZephirFile.daily_update(date)
      {
        zephir_file: zephir_file,
        target_dir: "production/zephir_daily/",
        title_log: "Start preprocessing for HT metadata in #{zephir_file}"
      }
    end

    def self.run(zephir_file:, target_dir:, title_log:)
      S.logger.info title_log

      zephir_file_basename = zephir_file.split(".").first

      Dir.mktmpdir(nil, S.scratch_dir) do |tmp_dir|
        local_file = File.join(tmp_dir, zephir_file)
        prefix = File.join(tmp_dir, zephir_file_basename) + "_"

        S.logger.info "creating scratch directory: #{tmp_dir}"
        Dir.mkdir(tmp_dir) unless Dir.exist?(tmp_dir)

        S.logger.info "fetching Zephir file"
        system("curl", "-u", S.ht_credentials,
          "#{S.ht_url}/catalog/#{zephir_file}", "-o",
          local_file)

        S.logger.measure_info("zephir processing") do
          Jobs::ZephirProcessing.run(zephir_file: local_file, batch_size: 200, threads: 2)
        end

        number_of_files = `ls #{prefix}* -1 | wc -l`.to_i
        S.logger.info "Finished splitting Zephir file #{zephir_file}. Created #{number_of_files} files"

        S.logger.info "Uploading files to sftp server"
        client = SFTP.client
        (0..number_of_files - 1).each do |num|
          suffix = num.to_s.rjust(2, "0")
          filename = "#{prefix}#{suffix}.json.gz"
          client.put(filename, target_dir)
          S.logger.info "uploaded #{filename}"
        end
        S.logger.info "Finished uploading zephir files to SFTP server"
      end
    end
  end
end
