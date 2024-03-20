# frozen_string_literal: true

solr_url = ENV.fetch("SOLR_URL")
file = ARGV.shift

exit(1) unless File.exist?(file)

success = system("bundle", "exec", "traject",
  "-c", "/app/readers/xml.rb",
  "-c", "/app/writers/solr.rb",
  "-c", "/app/indexers/settings.rb",
  "-c", "/app/indexers/common.rb",
  "-c", "/app/indexers/common_ht.rb",
  "-c", "/app/indexers/subject_topic.rb",
  "-c", "/app/indexers/umich.rb",
  #  "-c", "/app/indexers/umich_alma.rb",
  "-c", "/app/indexers/callnumbers.rb",
  "-u", solr_url,
  file)