class SFTP
  def initialize
    @user = ENV.fetch('ALMA_FILES_USER')
    @host = ENV.fetch('ALMA_FILES_HOST')
    @key = ENV.fetch('SSH_KEY_PATH')
  end
  #returns an array of items in a directory
  def ls(path="")
    array = ["sftp", "-oIdentityFile=#{@key}", "-oStrictHostKeyChecking=no", "-b", "-",  "#{@user}@#{@host}", 
      "<<<", "$'@ls #{path}'"]
    command = array.join(" ")
    `bash -c \"#{command}\"`.split("\n").map{|x| x.strip}
  end
end
