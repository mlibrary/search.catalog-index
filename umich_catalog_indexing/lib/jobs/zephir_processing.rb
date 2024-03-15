require "zinzout"
require_relative "zephir_processing/writer"
require_relative "zephir_processing/record"
require_relative "zephir_processing/overlap"

module Jobs
  module ZephirProcessing
    def self.run(full_zephir_file:, batch_size: 50)
      S.logger.info "batch size: #{batch_size}"
      records = []
      prefix = full_zephir_file.split(".")[0]
      writer = Writer.new(prefix: prefix)
      report = {
        skipped_umich: 0,
        skipped_overlap: 0,
        not_skipped: 0
      }
      Zinzout.zin("/app/scratch/#{full_zephir_file}") do |infile|
        count = 0
        infile.each_line do |line|
          record = Record.new(line)
          if record.is_umich?
            report[:skipped_umich] += 1
          else
            records.push(record)
          end
          if records.count == batch_size
            _process_batch(records, writer, report)
          end
          count += 1
          S.logger.info report if count % 50_000 == 0
        end
      end
      _process_batch(records, writer, report)
      writer.close
      S.logger.info report
    end

    def self._process_batch(records, writer, report)
      oclc_nums = records.map { |x| x.oclc_nums }.flatten.uniq
      umich_oclc_nums = Overlap.umich_oclc_nums(oclc_nums)
      records.each do |record|
        if record.oclc_nums.any? { |num| umich_oclc_nums.include?(num) }
          # S.logger.info("overlap check reject")
          report[:skipped_overlap] += 1
        else
          report[:not_skipped] += 1
          writer.write(record.raw)
        end
      end
      records.clear
    end
  end
end
