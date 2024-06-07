module Jobs
  module ZephirProcessing
    def self.run(zephir_file:, batch_size: 100, threads: 4)
      pool = Concurrent::FixedThreadPool.new(threads,
        max_queue: 200,
        fallback_policy: :caller_runs)

      lock = Concurrent::ReadWriteLock.new

      S.logger.info "batch size for overlap query: #{batch_size}"
      prefix = File.basename(zephir_file).split(".")[0]
      scratch_dir = File.dirname(zephir_file)
      writer = Writer.new(prefix: prefix, scratch_dir: scratch_dir)
      report = Concurrent::Hash.new
      report[:skipped_umich] = 0
      report[:skipped_overlap] = 0
      report[:not_skipped] = 0
      report[:no_full_text] = 0
      report[:count] = 0
      S.logger.info "Writing filtered records from #{zephir_file} to the #{scratch_dir} directory"
      Zinzout.zin(zephir_file) do |infile|
        infile.each_slice(batch_size) do |lines|
          records = lines.filter_map do |line|
            r = Record.new(line)
            if r.is_umich?
              report[:skipped_umich] += 1
              false # don't add it.
            elsif r.no_full_text?
              report[:no_full_text] += 1
              false
            else
              r
            end
          end
          pool.post(records) do |r|
            oclc_nums = r.map { |x| x.oclc_nums }.flatten.uniq
            umich_oclc_nums = Overlap.umich_oclc_nums(oclc_nums)

            lock.with_write_lock do
              r.each do |record|
                if record.oclc_nums.any? { |num| umich_oclc_nums.include?(num) }
                  report[:skipped_overlap] += 1
                else
                  report[:not_skipped] += 1
                  writer.write(record.raw)
                end
              end
            end
          end
          report[:count] += batch_size
          S.logger.info report if report[:count] % 100_000 == 0
        end
      end
      pool.shutdown
      pool.wait_for_termination
      writer.close
      S.logger.info report
    end
  end
end

require_relative "zephir_processing/record"
require_relative "zephir_processing/overlap"
require_relative "zephir_processing/writer"
