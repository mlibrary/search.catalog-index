require_relative "../lib/ht_traject/ht_dbh"


HathiTrust::DBH::DB[:ht_namespaces].select(:namespace, :institution).map(&:values).each do |n, i|
  puts [n, i].join("\t")
end

