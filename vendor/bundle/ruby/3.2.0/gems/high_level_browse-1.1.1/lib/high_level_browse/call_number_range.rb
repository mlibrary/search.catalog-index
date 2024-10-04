# frozen_string_literal: true

require "high_level_browse/range_tree"

# An efficient set of CallNumberRanges from which to get topics
class HighLevelBrowse::CallNumberRangeSet < HighLevelBrowse::RangeTree
  ANY_DIGIT = /\d/

  def has_digits(str)
    ANY_DIGIT.match?(str)
  end

  # Returns the array of topic arrays for the given LC string
  # @param [String] raw_lc A raw LC string (eg., 'qa 112.3 .A4 1990')
  # @return [Array<Array<String>>] Arrays of topic labels
  def topics_for(raw_lc)
    normalized = ::HighLevelBrowse::CallNumberRange.callnumber_normalize(raw_lc)
    search(normalized).map(&:topic_array).uniq
  rescue => e
    raise "Error getting topics for '#{raw_lc}': #{e}"
  end
end

# A callnumber-range keeps track of the original begin/end
# strings as well as the normalized versions, and can be
# serialized to JSON

class HighLevelBrowse::CallNumberRange
  include Comparable

  attr_reader :min, :max, :min_raw, :max_raw, :firstletter

  attr_accessor :topic_array, :redundant

  SPACE_OR_PUNCT = /\A[\s\p{Punct}]*(.*?)[\s\p{Punct}]*\Z/
  DIGIT_TO_LETTER = /(\d)([A-Z])/i

  # @nodoc
  # Remove spaces/punctuation from the ends of the string
  def self.strip_spaces_and_punct(str)
    str.gsub(SPACE_OR_PUNCT, '\1')
  end

  # @nodoc
  # Force a space between any digit->letter transition
  def self.force_break_between_digit_and_letter(str)
    str.gsub(DIGIT_TO_LETTER, '\1 \2')
  end

  # @nodoc
  # Preprocess the string, removing spaces/punctuation off the end
  # and forcing a space where there's a digit->letter transition
  # def self.preprocess(str)
  #   str ||= ''
  #   force_break_between_digit_and_letter(strip_spaces_and_punct(str)
  #   )
  # end

  # Normalize the callnumber in a slightly more sane way
  # @param [String] cn The raw callnumber to normalize
  CN = /\A\s*(?<letters>\p{L}{1,3})\s*(?<digits>\d{1,5}(?!\d))(?:\.(?<decimals>\d+))?(?<rest>.*)\Z/

  def self.callnumber_normalize(cs_str)
    return nil if cs_str.nil?

    cs_str = cs_str.downcase
    return cs_str if /\A\s*\p{L}{1,3}+\s*\Z/.match? cs_str # just letters

    m = CN.match(cs_str)
    return nil unless m

    digits = m[:digits].size.to_s + m[:digits]
    decimals = m[:decimals] ? "." + m[:decimals] : ""
    rest = cleanup_freetext(m[:rest])
    clean = m[:letters] + digits + decimals + " " + rest
    clean.strip.gsub(/\s+/, " ")
  end

  # @param [String] str String to clean up
  def self.cleanup_freetext(str)
    return "" if str.nil?

    s = str.strip
    return s if s == ""

    s = replace_dot_before_letter_with_space(s)
    s = remove_dots_between_letters(s)
    s = force_space_between_digit_and_letter(s)
    s.strip.gsub(/\s+/, " ")
  end

  def self.replace_dot_before_letter_with_space(s)
    s.gsub(/\.(\p{L})/, '\\1')
  end

  # @param [String] str
  def self.remove_dots_between_letters(str)
    str.gsub(/(\p{L})\.(\p{L})/, '\\1\\2')
  end

  def self.force_space_between_digit_and_letter(s)
    s.gsub(/(\d)(\p{L})/, '\\1 \\2')
  end

  def initialize(min:, max:, topic_array:)
    @illegal = false
    @redundant = false
    self.min = min
    self.max = max
    @topic_array = topic_array
    @firstletter = self.min[0] unless @illegal
  end

  # Compare based on @min, then end
  # @param [CallNumberRange] o the range to compare to
  def <=>(other)
    [min, max] <=> [other.min, other.max]
  end

  def to_s
    "[#{min_raw} - #{max_raw}]"
  end

  def reconstitute(min, max, min_raw, max_raw, firstletter, topic_array)
    @min = min
    @max = max
    @min_raw = min_raw
    @max_raw = max_raw
    @firstletter = firstletter
    @topic_array = topic_array
  end

  # Two ranges are equal if their @min, @max, and topic array
  # are all the same
  # @param [CallNumberRange] o the range to compare to
  def ==(other)
    @min == other.min and @max == other.max and @topic_array == other.topic_array
  end

  # @nodoc
  # JSON roundtrip
  def to_json(*a)
    {"json_class" => self.class.name, "data" => [@min, @max, @min_raw, @max_raw, @firstletter, @topic_array]}.to_json(*a)
  end

  # @nodoc
  def self.json_create(h)
    cnr = allocate
    cnr.reconstitute(*(h["data"]))
    cnr
  end

  # In both @min= and end=, we also rescue any parsing errors
  # and simply set the @illegal flag so we can use it later on.
  def min=(x)
    @min_raw = x
    possible_min = self.class.callnumber_normalize(x)
    if possible_min.nil? # didn't normalize
      @illegal = true
      nil
    else
      @min = possible_min
    end
  end

  # Same as start. Set the illegal flag if we get an error
  def max=(x)
    @max_raw = x
    possible_max = self.class.callnumber_normalize(x)
    if possible_max.nil? # didn't normalize
      @illegal = true
      nil
    else
      @max = possible_max + "~" # add a tilde to make it a true endpoint
    end
  end

  def illegal?
    @illegal
  end

  def surrounds(other)
    @min <= other.min and @max >= other.max
  end

  def contains(x)
    @min <= x and @max >= x
  end

  alias_method :cover?, :contains
  alias_method :member?, :contains
end
