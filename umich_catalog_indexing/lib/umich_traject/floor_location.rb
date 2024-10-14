# frozen_string_literal: true

require 'json'

module UMich
  class FloorLocation
    def self.configure(json_file)
      @config = Hash.new([])
      JSON.parse(IO.read(json_file)).each_pair do |building, pair|
        pair.each do |collection, location|
          key = normalize_collection(building, collection)
          #@config[key] = ::Spectrum::FloorLocation(location)
          @config[key] = ::UMich::FloorLocation(location)
        end
      end
      self
    end

    def self.resolve(building, collection, callno)
      key = normalize_collection(building, collection)
      @config[key].find do |item|
        return item.text if item.match(callno)
      end
      ''
    end

    def self.normalize_collection(building, collection)
      "#{building} #{collection}".strip.upcase
    end

    attr_reader :text, :start, :stop

    def initialize(location)
      @start = location['start']
      @stop  = location['stop']
      @text  = location['text']
    end

    def match(callno)
      callno = normalize(callno)
      start <= callno && callno < stop
    end

    def normalize(_callno)
      nil
    end
  end

  def self.FloorLocation(location)
    return location.map { |item| FloorLocation(item) } if Array === location

    case location['type']
    when 'Everything'
      EverythingFloorLocation
    when 'Dewey'
      DeweyFloorLocation
    when 'LC'
      LCFloorLocation
    else
      FloorLocation
    end.new(location)
  end

  class EverythingFloorLocation < FloorLocation
    def match(_callno)
      true
    end
  end

  class DeweyFloorLocation < FloorLocation
    def normalize(callno)
      callno.to_f
    end
  end

  class LCFloorLocation < FloorLocation
    def normalize(callno)
      if match = callno.downcase.match(/^\s*([a-z]+)\s*(\d+)?(\.\d+)?(.*)$/)
        letters = match[1]
        numbers = match[2] || ''
        decimal = (match[3] || '').sub(".","").ljust(5, '0')
        rest    = match[4] || ''
        return letters unless (letters + numbers) =~ /\S/
        numbers = '0' if numbers.nil? || numbers.empty?
        return format('%s%04d.%s%s', letters, numbers.to_i, decimal, rest)
      end
      ''
    end
  end
end
