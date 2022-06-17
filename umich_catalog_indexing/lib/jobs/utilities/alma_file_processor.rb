require "securerandom"
require "fileutils"
module Jobs
  module Utilities
    class AlmaFileProcessor
      attr_reader :xml_file
      def initialize(path:, destination: "/app/scratch/#{SecureRandom.alphanumeric(8)}") 
        @src_path = path
        @destination_dir = destination
        @output_file_path = "#{destination}/#{File.basename(path)}"
        @xml_file = "#{@output_file_path.split(".").first}.xml"  
      end
      def run(sftp: SFTP.client, tar: lambda{|path, destination| system("tar", "xzvf", path, "-C", destination) }, mkdir: lambda{|dir| Dir.mkdir(dir) unless Dir.exist?(dir)})
        mkdir.call(@destination_dir)
        sftp.get(@src_path, @destination_dir)
        tar.call(@output_file_path, @destination_dir)
      end
      def clean(delete = lambda{|file| FileUtils.remove_dir(file) })
        delete.call(@destination_dir)
      end
      def scratch_dir
        @destination_dir
      end
    end
  end
end
