module Jobs
  module Utilities
    class SFTP
      def initialize
        @user = ENV.fetch('ALMA_FILES_USER')
        @host = ENV.fetch('ALMA_FILES_HOST')
        @key = ENV.fetch('SSH_KEY_PATH')
      end
      #returns an array of items in a directory
      def ls(path="")
        run_an_sftp_command("$'@ls #{path}'").split("\n").map{|x| x.strip}
      end
      def get(path, destination)
        run_an_sftp_command("$'@get #{path} #{destination}'")
      end
      private
      def run_an_sftp_command(command)
        base = ["sftp", "-oIdentityFile=#{@key}", "-oStrictHostKeyChecking=no", "-b", "-",  "#{@user}@#{@host}", "<<<"]
        base.push(command)
        `bash -c \"#{base.join(" ")}\"`
      end
    end
  end
end
