# frozen_string_literal: true

require_relative "normalize"

module Common
  class Subjects
    class LCSubject
      LC_SUBJECT_FIELD_TAGS = ["600", "610", "611", "630", "650", "651", "655"]
      LC_SUBJECT_FIELD_TAGS.freeze

      include Common::Subjects::Normalize

      # Create an LC Subject object from the passed field
      # @param [MARC::DataField] field _that has already been determined to be LC_
      # @return [LCSubject] An LC Subject or appropriate subclass
      def self.from_field(field)
        case field.tag
        when "658"
          LCSubject658.new(field)
        when "662"
          LCSubjectHierarchical.new(field)
        when "752"
          LCAddedEntryHeirarchical.new(field)
        else
          new(field)
        end
      end

      # Only certain subject tags can be LCSH tags. Of those, they need to have
      # a ind2=0 to be a valid LCSH heading. $2 also says something about the
      # nature of the heading. We expect it to be nil when ind2=0, but if it
      # had "naf" or "lcsh" in it that would be weird but fine. Anything else
      # in $2 is not LCSH.
      #
      # @param [MARC::DataField] field A 6XX field
      # @return [Boolean]
      def self.lc_subject_field?(field)
        LC_SUBJECT_FIELD_TAGS.include?(field.tag) &&
          field.indicator2 == "0" &&
          lcsh_subject_field_2?(field)
      end

      # @param [MARC::DataField] an lcsh field
      def self.lcsh_subject_field_2?(field)
        return true if field["2"].nil?
        if field["2"].include?("lcsh") || field["2"].include?("naf")
          S.logger.warn("LCSH_UNNECESSARY_SUBFIELD_2", field: field.to_s)
          return true
        end
        S.logger.warn("LCSH_SUBFIELD_2_NOT_LCSH", field: field.to_s)
        false
      end

      def initialize(field)
        @field = field
      end

      # Get all the subfields that have data (as opposed to field-level metadata, like a $2)
      def subject_data_subfield_codes
        @field.select { |sf| ("a".."z").cover?(sf.code) }
      end

      def default_delimiter
        "--"
      end

      # Here for testing purposes to distinguish from the Non LC subjects
      # @return [Boolean]
      def lc_subject_field?
        true
      end

      # Only some fields get delimiters before them in a standard LC Subject field
      def delimited_fields
        %w[v x y z]
      end

      # Most subject fields are constructed by joining together the alphabetic subfields
      # with either a '--' (before a $v, $x, $y, or $z) or a space (before everything else).
      # @return [String] An appropriately-delimited string
      def subject_string(padding: false)
        delimiter = _delimiter_string(padding)
        str = subject_data_subfield_codes.map do |sf|
          case sf.code
          when *delimited_fields
            "#{delimiter}#{sf.value}"
          else
            " #{sf.value}"
          end
        end.join("").gsub(/\A\s*#{delimiter}/, "") # pull off a leading delimiter if it's there

        normalize(str)
      end

      def _delimiter_string(padding)
        padding ? " #{default_delimiter} " : default_delimiter
      end
    end

    class LCSubject658 < LCSubject
      # Format taken from the MARC 658 documentation
      # @return [String] Subject string ready for output
      def subject_string(padding: false)
        delimiter = _delimiter_string(padding)
        str = subject_data_subfield_codes.map do |sf|
          case sf.code
          when "b"
            ": #{sf.value}"
          when "c"
            " [#{sf.value}]"
          when "d"
            # we do "--" instead of "-" because a single hyphen is too
            # confusing
            "#{delimiter}#{sf.value}"
          else
            " #{sf.value}"
          end
        end.join("").gsub(/\A\s*#{delimiter}/, "")
        normalize(str)
      end
    end

    # Purely hierarchical fields can just have all their parts
    # joined together with the delimiter
    class LCSubjectHierarchical < LCSubject
      # At least one subject field in LC, the 662, just gets delimiters everywhere
      # Format taken from the MARC 662 documentation
      # @return [String] Subject string ready for output
      def subject_string(padding: false)
        delimiter = _delimiter_string(padding)
        normalize(subject_data_subfield_codes.map(&:value).join(delimiter))
      end
    end

    # Taken from https://www.loc.gov/marc/bibliographic/bd752.html
    class LCAddedEntryHeirarchical < LCSubject
      def delimited_fields
        %w[a b c d e f g h]
      end

      def default_delimiter
        "-"
      end
    end
  end
end
