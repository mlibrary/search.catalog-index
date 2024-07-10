module Common::Subject
  class Remediator
    # will be subject headings translation map
    def initialize(mapping = JSON.parse(File.read(File.join(S.translation_map_dir, "umich", "subject_heading_remediation.json"))))
      @mapping = mapping
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
        unless match["450"][sf.code]
            &.map { |x| _normalize_sf(x) }
            &.include?(_normalize_sf(sf.value))
          MARC::Subfield.new(sf.code, sf.value)
        end
      end

      remediated_field = MARC::DataField.new(field.tag, field.indicator1, "7", *sfields)
      match["150"].keys.each do |code|
        match["150"][code].each do |value|
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
      match["450"].map do |f|
        sfields = field.subfields.filter_map do |sf|
          unless match["150"][sf.code]
              &.map { |x| _normalize_sf(x) }
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
      @mapping.each do |this_to_that|
        match = this_to_that["150"].keys.all? do |code|
          this_to_that["150"][code].all? do |dep_sf_value|
            _sf_in_field?(code: code, sf_value: dep_sf_value, test_field: field)
          end
        end
        return this_to_that if match
      end
      nil
    end

    def _matching_deprecated_field(field)
      @mapping.each do |this_to_that|
        match = this_to_that["450"].find do |deprecated_subfields|
          deprecated_subfields.keys.all? do |code|
            deprecated_subfields[code].all? do |dep_sf_value|
              _sf_in_field?(code: code, sf_value: dep_sf_value, test_field: field)
            end
          end
        end
        return {"150" => this_to_that["150"], "450" => match} if match
      end
      nil
    end

    def _sf_in_field?(code:, sf_value:, test_field:)
      test_sf_values = test_field.subfields.filter_map do |sf|
        _normalize_sf(sf.value) if sf.code == code
      end
      test_sf_values.include?(_normalize_sf(sf_value))
    end

    def _normalize_sf(str)
      str&.downcase&.gsub(/[^A-Za-z0-9\s]/i, "")
    end
  end
end
