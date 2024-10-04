$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "marc/fastxmlwriter"

require "minitest"
require "minitest/spec"
require "minitest/autorun"

def test_data_dir
  File.expand_path(File.join(File.dirname(__FILE__), "test_data"))
end

def test_data(relative_path)
  File.expand_path(File.join("test_data", relative_path), File.dirname(__FILE__))
end
