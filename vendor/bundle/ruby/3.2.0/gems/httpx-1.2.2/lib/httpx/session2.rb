# frozen_string_literal: true

require_relative "session"
module HTTPX
  class Session
    def initialize(options = EMPTY_HASH, &blk)
      @options = self.class.default_options.merge(options)
      @responses = {}
      @persistent = @options.persistent
      wrap(&blk) if blk
    end

    def wrap
      begin
        prev_persistent = @persistent
        @persistent = true
        yield self
      ensure
        @persistent = prev_persistent
      end
    end
  end
end
