# encoding: utf-8
require 'traject/marc4j_reader'
require 'marc'
require 'stringio'
require_relative 'marc4j_fix'

module Traject
  class MultiFileMarc4JReader < Traject::Marc4JReader

    # @param [Traject::Reader]
    def initialize(input_stream, settings)
      @settings = settings
      globs = get_and_validate_globs(settings)
      super
      @inputs = streams_from_globs(globs)
    end

    alias_method :old_each, :each

    def each
      return to_enum(:each) unless block_given?
      @inputs.each do |stream|
        filename = stream.first
        @input_stream = stream.last
        logger.info("Processing #{filename}")

        @internal_reader = create_marc_reader!
        self.old_each do |r|
          yield r
        end
      end
    end

    private

    def get_and_validate_globs(settings)
      globstr = settings['source_glob']
      globs = globstr.split(/\s*,\s*/).sort
      raise "#{self} requires setting 'source_glob' to be set" if globs.empty?
      globs
    end

    def open_stream(filename)
      if @settings["marc_source.encoding"] == "xml"
        File.open(filename, 'r:utf-8')
      else
        File.open(filename, 'r')
      end
    end

    def streams_from_globs(globs)
      streammap = globs.each_with_object({}) { |g, h| h[g] = Dir.glob(g).map { |f| [f, open_stream(f)] } }
      streammap.each_pair do |g, s|
        if s.empty?
          logger.warn "Glob '#{g}' matched no files"
        else
          logger.info "Glob '#{g}' matched #{s.size} files"
        end
      end
      streams = streammap.values.flatten(1)
      if streams.empty?
        msg = "#{self.class} aborting. No files matching any of '#{globs.join(",")}' found"
        logger.fatal(msg)
        exit 1
      end
      streams
    end

  end
end
   
