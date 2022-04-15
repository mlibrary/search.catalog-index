require "jruby"
require "high_level_browse"
path = "./lib/translation_maps"

#does file exist and is file older than one day?
if !File.exists?("#{path}/hlb.json.gz") or File.stat(path).mtime < Time.now - (60*60*24) 
  HighLevelBrowse.fetch_and_save(dir: path)
  puts "#{path}/hlb.json.gz is less than one day old. Did not update"
else
  puts "#{path}/hlb.json.gz is less than one day old. Did not update"
end
