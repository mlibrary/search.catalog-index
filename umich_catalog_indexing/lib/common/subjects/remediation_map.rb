module Common
  class Subjects
    class RemediationMap
      attr_reader :mapping, :normalized_mapping

      def initialize(mapping = JSON.parse(File.read(File.join(S.translation_map_dir, "umich", "subject_heading_remediation.json"))))
        @mapping = mapping
        @normalized_mapping = _create_normalized_mapping
      end

      # @return [Array<Hash>] returns a version of the mapping where the values
      # of headings have been downcased and everything except letters, numbers,
      # and spaces has been removed.
      def _create_normalized_mapping
        @mapping.map do |heading|
          new_heading = {}
          heading["1xx"].keys.each do |code|
            new_heading[code] = heading["1xx"][code].map do |value|
              normalize_sf(value)
            end
          end

          dep_headings = heading["4xx"].map.with_index do |_, index|
            dep_heading = {}
            heading["4xx"][index].keys.each do |code|
              dep_heading[code] = heading["4xx"][index][code].map do |value|
                normalize_sf(value)
              end
            end
            dep_heading
          end
          {
            "1xx" => new_heading,
            "4xx" => dep_headings
          }
        end
      end

      def normalize_sf(str)
        str&.downcase&.gsub(/[^A-Za-z0-9\s]/i, "")
      end
    end
  end
end
