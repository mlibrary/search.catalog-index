module Jobs
  module Utilities
    # Copies file from sftp and handles cleanup
    class FileProcessor
      attr_reader :local_path
      def initialize(remote_path:, local_dir: "/app/scratch/#{SecureRandom.alphanumeric(8)}")
        @local_dir = local_dir
        @local_path = File.join(@local_dir, File.basename(remote_path))
        @remote_path = remote_path
      end

      def run(sftp: SFTP.client, mkdir: lambda { |dir| Dir.mkdir(dir) unless Dir.exist?(dir) })
        mkdir.call(@local_dir)
        sftp.get(@remote_path, @local_dir)
      end

      def clean(delete = lambda { |file| FileUtils.remove_dir(file) })
        delete.call(@local_dir)
      end

      def scratch_dir
        @local_dir
      end
    end
  end
end
