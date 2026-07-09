module Indexer
  module IndexFull
    def self.alma
      S.logger.info "Starting submission of Alma monthly full jobs"

      all_files = SFTP.client.ls("#{S.alma_full_dir_path}/*")
      latest_date = all_files.map do |f|
        File.basename(f).split("_")[1]
      end.uniq.max

      files = all_files.select { |x| x.match?(latest_date) }

      files.each do |file|
        S.logger.info "Sending job to index #{file} into reindex solr: #{S.reindex_solr_url}"
        IndexIt.set(queue: "reindex").perform_async(file, S.reindex_solr_url)
      end

      S.logger.info "Finished submitting Alma monthly full jobs"
    end

    def self.zephir
      S.logger.info "Starting submission of Zephir monthly full jobs"

      zephir_file = Jobs::Utilities::ZephirFile.latest_monthly_full
      zephir_file_basename = zephir_file.split(".").first

      files = SFTP.client.ls("#{S.zephir_full_dir_path}/#{zephir_file_basename}_*")

      files.each do |file|
        S.logger.info "Sending job to index #{file} into reindex solr: #{S.reindex_solr_url}"
        IndexJson.set(queue: "reindex").perform_async(file, S.reindex_solr_url)
      end

      S.logger.info "Finished submitting Zephir monthly full jobs"
    end
  end
end
