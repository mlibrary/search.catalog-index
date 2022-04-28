module Jobs
  module Utilities
    class AlmaFileProcessor
      attr_reader :xml_file
      def initialize(path:, destination: "/app/scratch") 
        @src_path = path
        @destination_dir = destination
        @output_file_path = "#{destination}/#{File.basename(path)}"
        @xml_file = "#{@output_file_path.split(".").first}.xml"  
      end
      def run(sftp: SFTP.new, tar: lambda{|path, destination| system("tar", "xzvf", path, "-C", destination) })
        sftp.get(@src_path, @destination_dir)
        tar.call(@output_file_path, @destination_dir)
      end
      def clean(delete = lambda{|file| File.delete(file) })
        delete.call(@xml_file)
        delete.call(@output_file_path)
      end
    end
  end
end
