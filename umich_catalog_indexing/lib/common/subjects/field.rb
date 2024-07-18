module Common
  class Subjects
    class Field
      extend Forwardable
      attr_reader :normalized_sfs

      def_delegators :@field, :tag, :indicator2, :[], :subfields

      def initialize(field:, remediation_map:, normalized_sfs: nil)
        @field = field
        @mapping = remediation_map.mapping
        @normalized_mapping = remediation_map.normalized_mapping
        @normalized_sfs = normalized_sfs
      end

      def remediable?
        !!_matching_deprecated_field
      end

      # Given a subject field, is it one that has already been remediated?
      def already_remediated?
        !!_matching_remediated_field
      end

      #
      # Given a remediatable field, return the remediated field
      # @param field [MARC::DataField] subject field to remediate
      # [MARC::DataField] the remediated field
      def to_remediated
        match = _matching_deprecated_field

        sfields = @field.subfields.filter_map.with_index do |sf, index|
          unless match["normalized"]["450"][sf.code]
              &.include?(normalized_sfs[index]["value"])
            MARC::Subfield.new(sf.code, sf.value)
          end
        end

        remediated_field = MARC::DataField.new(@field.tag, @field.indicator1, "7", *sfields)
        match["given"]["150"].keys.each do |code|
          match["given"]["150"][code].each do |value|
            remediated_field.append(MARC::Subfield.new(code, value))
          end
        end
        remediated_field.subfields.sort_by!(&:code)
        remediated_field.append(MARC::Subfield.new("2", "miush"))

        remediated_field
      end

      # Given a remediatable field, return the deprecated versions of that field
      # @param field [MARC::DataField] remediated subject field that needs
      # deprecated fields [Array<MARC::DataField>] List of deprecated fields
      def to_deprecated
        match = _matching_remediated_field
        match["given"]["450"].map do |f|
          sfields = @field.subfields.filter_map.with_index do |sf, index|
            unless match["normalized"]["150"][sf.code]
                &.include?(normalized_sfs[index]["value"])
              MARC::Subfield.new(sf.code, sf.value)
            end
          end
          deprecated_field = MARC::DataField.new(@field.tag, @field.indicator1, @field.indicator2, *sfields)
          f.keys.each do |code|
            f[code].each do |value|
              deprecated_field.append(MARC::Subfield.new(code, value))
            end
          end
          deprecated_field.subfields.sort_by!(&:code)
          deprecated_field
        end
      end

      def _matching_deprecated_field
        @_matching_deprecated_field ||= @mapping.each_with_index do |this_to_that, index|
          match_index = this_to_that["450"].find_index.with_index do |deprecated_subfields, dep_index|
            deprecated_subfields.keys.all? do |code|
              @normalized_mapping[index]["450"][dep_index][code].all? do |dep_sf_value|
                _sf_in_field?(code: code, sf_value: dep_sf_value)
              end
            end
          end
          unless match_index.nil?
            return {
              "given" => {
                "150" => this_to_that["150"],
                "450" => @mapping[index]["450"][match_index]
              },
              "normalized" => {
                "150" => @normalized_mapping[index]["150"],
                "450" => @normalized_mapping[index]["450"][match_index]
              }
            }
          end
        end
        nil
      end

      def _matching_remediated_field
        @_matching_remediated_field ||= @mapping.each_with_index do |this_to_that, index|
          match = this_to_that["150"].keys.all? do |code|
            @normalized_mapping[index]["150"][code].all? do |dep_sf_value|
              _sf_in_field?(code: code, sf_value: dep_sf_value)
            end
          end

          if match
            return {
              "given" => this_to_that,
              "normalized" => @normalized_mapping[index]
            }
          end
        end
        nil
      end

      # def normalized_sfs
      # @normalized_sfs ||= @field.subfields.map do |sf|
      # {"code" => sf.code, "value" => _normalize_sf(sf.value)}
      # end
      # end

      def _sf_in_field?(code:, sf_value:)
        test_sf_values = normalized_sfs.filter_map do |sf|
          sf["value"] if sf["code"] == code
        end
        test_sf_values.include?(sf_value)
      end

      # def _normalize_sf(str)
      # str&.downcase&.gsub(/[^A-Za-z0-9\s]/i, "")
      # end
    end
  end
end
