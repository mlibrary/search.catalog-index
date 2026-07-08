require "sftp"
S.register(:sftp_user) { ENV.fetch("ALMA_FILES_USER", "alma") }
S.register(:sftp_host) { ENV.fetch("ALMA_FILES_HOST", "sftp") }
S.register(:ssh_key_path) { ENV.fetch("SSH_KEY_PATH", "/etc/secret-volume/id_rsa") }

SFTP.configure do |config|
  config.user = S.sftp_user
  config.host = S.sftp_host
  config.key_path = S.ssh_key_path
end

S.register(:alma_update_dir_path) do
  ENV.fetch("DAILY_ALMA_FILES_PATH", "bibs")
end
S.register(:zephir_update_dir_path) do
  ENV.fetch("ZEPHIR_UPDATE_DIR_PATH", "bibs")
end
S.register(:alma_update_file_paths) do
  SFTP.client.ls(S.alma_update_dir_path)
end
