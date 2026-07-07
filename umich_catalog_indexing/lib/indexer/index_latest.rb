module Indexer
  module IndexLatest
    def self.zephir
      S.logger.info "Starting submission of HathiTrust daily update jobs"

      zephir_file = Jobs::Utilities::ZephirFile.latest_daily_update
      zephir_file_basename = zephir_file.split(".").first

      files = SFTP.client.ls("production/zephir_daily/#{zephir_file_basename}_*")

      files.each do |file|
        if S.solrcloud_on?
          S.logger.info "Sending job to index #{file} into live solr: #{S.live_solr_url}"
          IndexJson.perform_async(file, S.live_solr_url)
        else
          S.production_solr_urls.each do |solr_url|
            S.logger.info "Sending job to index #{file} into #{solr_url}"
            IndexJson.perform_async(file, solr_url)
          end
        end
      end

      S.logger.info "Finished submission of HathiTrust daily update jobs"
    end
  end
end
