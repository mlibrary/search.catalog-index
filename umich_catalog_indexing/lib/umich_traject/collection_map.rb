module Traject
  module UMich
    COLLECTION_MAP = YAML.load_file("lib/translation_maps/umich/collection_map.yaml")

    def self.collection_map(library_location)
      library = library_location.split(" ").first
      COLLECTION_MAP.dig(library, "collections", library_location)
    end
  end
end
