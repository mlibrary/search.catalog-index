module Common
  class Subjects
    class Remediator
      def self.normalize_sf(str)
        str&.downcase&.gsub(/[^A-Za-z0-9\s]/i, "")
      end

      # will be subject headings translation map
      def initialize(mapping = JSON.parse(File.read(File.join(S.translation_map_dir, "umich", "subject_heading_remediation.json"))))
        @mapping = mapping
        @normalized_mapping = _create_normalized_mapping
      end

      # Given a subject field, is it one that will need remediating?
      def remediable?(field)
        !!_matching_deprecated_field(field)
      end

      # Given a subject field, is it one that has already been remediated?
      def already_remediated?(field)
        !!_matching_remediated_field(field)
      end

      # Given a remediatable field, return the remediated field
      # @param field [MARC::DataField] subject field to remediate
      # [MARC::DataField] the remediated field
      def to_remediated(field)
        match = _matching_deprecated_field(field)

        sfields = field.subfields.filter_map do |sf|
          unless match["normalized"]["450"][sf.code]
              # &.map { |x| _normalize_sf(x) }
              &.include?(_normalize_sf(sf.value))
            MARC::Subfield.new(sf.code, sf.value)
          end
        end

        remediated_field = MARC::DataField.new(field.tag, field.indicator1, "7", *sfields)
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
      def to_deprecated(field)
        match = _matching_remediated_field(field)
        match["given"]["450"].map do |f|
          sfields = field.subfields.filter_map do |sf|
            unless match["normalized"]["150"][sf.code]
                &.include?(_normalize_sf(sf.value))
              MARC::Subfield.new(sf.code, sf.value)
            end
          end
          deprecated_field = MARC::DataField.new(field.tag, field.indicator1, field.indicator2, *sfields)
          f.keys.each do |code|
            f[code].each do |value|
              deprecated_field.append(MARC::Subfield.new(code, value))
            end
          end
          deprecated_field.subfields.sort_by!(&:code)
          deprecated_field
        end
      end

      def _matching_remediated_field(field)
        normalized_sfs = _normalized_subfields(field)
        @mapping.each_with_index do |this_to_that, index|
          match = this_to_that["150"].keys.all? do |code|
            @normalized_mapping[index]["150"][code].all? do |dep_sf_value|
              _sf_in_field?(code: code, sf_value: dep_sf_value, test_field: field, normalized_sfs: normalized_sfs)
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

      def _matching_deprecated_field(field)
        normalized_sfs = _normalized_subfields(field)
        @mapping.each_with_index do |this_to_that, index|
          match_index = this_to_that["450"].find_index.with_index do |deprecated_subfields, dep_index|
            deprecated_subfields.keys.all? do |code|
              @normalized_mapping[index]["450"][dep_index][code].all? do |dep_sf_value|
                _sf_in_field?(code: code, sf_value: dep_sf_value, test_field: field, normalized_sfs: normalized_sfs)
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

      def _normalized_subfields(field)
        field.subfields.map do |sf|
          {"code" => sf.code, "value" => _normalize_sf(sf.value)}
        end
      end

      def _sf_in_field?(code:, sf_value:, test_field: nil, normalized_sfs: nil)
        test_sf_values = normalized_sfs.filter_map do |sf|
          sf["value"] if sf["code"] == code
        end
        test_sf_values.include?(sf_value)
      end

      def _create_normalized_mapping
        @mapping.map do |heading|
          new_heading = {}
          heading["150"].keys.each do |code|
            new_heading[code] = heading["150"][code].map do |value|
              _normalize_sf(value)
            end
          end

          dep_headings = heading["450"].map.with_index do |_, index|
            dep_heading = {}
            heading["450"][index].keys.each do |code|
              dep_heading[code] = heading["450"][index][code].map do |value|
                _normalize_sf(value)
              end
            end
            dep_heading
          end
          {
            "150" => new_heading,
            "450" => dep_headings
          }
        end
      end

      def _normalize_sf(str)
        str&.downcase&.gsub(/[^A-Za-z0-9\s]/i, "")
      end
    end
  end
end
