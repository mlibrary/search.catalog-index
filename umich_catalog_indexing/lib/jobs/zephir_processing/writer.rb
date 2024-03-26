require "zinzout"
module Jobs
  module ZephirProcessing
    class Writer
      attr_reader :io
      def initialize(prefix:, scratch_dir: S.scratch_dir, batch_size: S.marc_record_batch_size)
        @batch_size = batch_size
        @prefix = prefix
        @scratch_dir = scratch_dir

        @line_count = 0
        @file_count = 0
        @current_file_path = _current_file_path
        @io = Zinzout.zout(@current_file_path)
      end

      def write(line)
        @io.puts(line)
        _update_current_file
      end

      def close
        @io.close
      end

      def _update_current_file
        @line_count += 1
        return if @line_count < @batch_size
        close
        @line_count = 0
        @file_count += 1
        @current_file_path = _current_file_path
        @io = Zinzout.zout(@current_file_path)
      end

      def _current_file_path
        suffix = @file_count.to_s.rjust(2, "0")
        File.join(@scratch_dir, "#{@prefix}_#{suffix}.json.gz")
      end
    end
  end
end
