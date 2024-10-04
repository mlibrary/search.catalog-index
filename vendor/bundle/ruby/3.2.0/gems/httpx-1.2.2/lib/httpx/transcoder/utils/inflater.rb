module HTTPX
  module Transcoder
    class Inflater
      def initialize(bytesize)
        @bytesize = bytesize
      end

      def call(chunk)
        buffer = @inflater.inflate(chunk)
        @bytesize -= chunk.bytesize
        if @bytesize <= 0
          buffer << @inflater.finish
          @inflater.close
        end
        buffer
      end
    end
  end
end
