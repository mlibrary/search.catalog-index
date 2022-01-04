require_relative '../lib/umich_utilities/umich_utilities'
require 'yaml'
require 'optparse'
#require 'pry-debugger-jruby'

path = '' 
force = false
OptionParser.new do |opts|
  opts.on("--path PATH") do |x|
    path = x
  end
  opts.on("-f", "--force") do |x|
    force = true
  end
end.parse!

#puts path

if force or !File.exists?(path) or File.stat(path).mtime < Time.now - (60*60*24) #is file older than one day?
  temporary_path = "#{path}.temporary"
  File.open(temporary_path, 'w'){|f| f.write UmichUtilities::LibraryLocationList.new.list.to_yaml(line_width: 1000 ) }
  if !File.exists?(temporary_path) || File.size?(temporary_path) < 15
    puts "Error: Did not update. Failed to load file"
  else
    File.rename(temporary_path, path)
    puts "updated #{path} with Library and Location Info"
  end
else
  puts "#{path} is less than one day old. Did not update"
end
#puts 
