module Common::Subject
  class Remediator
    # will be subject headings translation map
    def initialize(mapping = nil)
      @mapping = mapping
    end

    # Given a subject field, is it one that will need remediating?
    def remediable?(field)
      @mapping.map { |x| x["450"] }.any? do |deprecated_subfields|
        deprecated_subfields.keys.all? do |code|
          deprecated_subfields[code].all? do |dep_sf_value|
            _dep_sf_in_field?(code: code, dep_sf_value: dep_sf_value, test_field: field)
          end
        end
      end
    end

    def _dep_sf_in_field?(code:, dep_sf_value:, test_field:)
      test_sf_values = test_field.subfields.filter_map do |sf|
        sf.value if sf.code == code
      end
      test_sf_values.include?(dep_sf_value)
    end

    # Given a subject field, is it one that has already been remediated?
    def already_remediated?(field)
    end

    # Given a remediatable field, return the remediated field
    # @param field [MARC::DataField] subject field to remediate
    # [MARC::DataField] the remediated field
    def to_remediated(field)
    end

    # Given a remediatable field, return the remediated field
    # @param field [MARC::DataField] remediated subject field that needs deprecated fields
    # [Array<MARC::DataField>] List of deprecated fields
    def to_deprecated(field)
    end
  end
end
