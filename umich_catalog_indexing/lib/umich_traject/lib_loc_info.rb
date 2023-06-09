module UMich
  module LibLocInfo
    LIBLOCINFO = YAML.load_file("lib/translation_maps/umich/libLocInfo.yaml") 

    def self.display_name(library, location)
      LIBLOCINFO.dig("#{library} #{location}", "name") || "#{library} #{location}"
    end
    def self.info_link(library, location)
      LIBLOCINFO.dig("#{library} #{location}", "info_link")
    end
    def self.fulfillment_unit(library, location)
      LIBLOCINFO.dig("#{library} #{location}", "fulfillment_unit") || "General"
    end
    def self.location_type(library, location)
      LIBLOCINFO.dig("#{library} #{location}", "location_type") || "OPEN"
    end
  end
end
