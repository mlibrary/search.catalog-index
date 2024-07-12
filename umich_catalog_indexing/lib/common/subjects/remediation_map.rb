module Common
  class Subjects
    class RemediationMap
      attr_reader :mapping, :normalized_mapping
      def initialize(mapping = JSON.parse(File.read(File.join(S.translation_map_dir, "umich", "subject_heading_remediation.json"))))
        @mapping = mapping
        @normalized_mapping = _create_normalized_mapping
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
