require "zinzout/version"
require 'zlib'

module Zinzout
  class Error < StandardError; end

  DEFAULT_ENCODING = "utf-8"

  def self.zin(filename = nil, encoding: DEFAULT_ENCODING)
    zin = Zin.new(filename, encoding)
    if block_given?
      yield zin.io
      zin.close
    end
    zin.io
  end

  def self.zout(filename = nil, encoding: DEFAULT_ENCODING)
    zout = Zout.new(filename, encoding)
    if block_given?
      yield zout.io
      zout.close
      nil
    else
      zout.io
    end
  end

  class Zin
    def self.new(filename, encoding)
      if filename.nil?
        ZinStdin.new
      else
        ZinFile.new(filename.to_s, encoding)
      end
    end
  end

  class Zout
    def self.new(filename, encoding)
      if filename.nil?
        ZoutStdout.new
      else
        ZoutFile.new(filename.to_s, encoding)
      end
    end
  end


  class ZinFile
    attr_reader :io

    def initialize(filename, encoding)
      @io = io_from_file(filename, encoding)
    end

    def io_from_file(filename, encoding)
      Zlib::GzipReader.open(filename, encoding: encoding)
    rescue Zlib::GzipFile::Error
      ::File.open(filename, 'r', encoding: encoding)
    end

    def close
      @io.close
    end
  end

  class ZoutFile < ZinFile
    def io_from_file(filename, encoding)
      if /\.gz\Z/.match(filename)
        Zlib::GzipWriter.open(filename, nil, nil, encoding: encoding)
      else
        File.open(filename, 'w', encoding: encoding)
      end
    end
  end


  class ZinStdin
    attr_reader :io

    def initialize
      @io = STDIN
    end

    def close
      # no op
    end
  end

  class ZoutStdout < ZinStdin
    def initialize
      @io = STDOUT
    end
  end


end
