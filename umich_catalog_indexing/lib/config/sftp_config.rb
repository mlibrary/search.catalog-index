require "sftp"
require_relative "../services"
SFTP.configure do |config|
  config.user = S.sftp_user
  config.host = S.sftp_host
  config.key_path = S.ssh_key_path
end
