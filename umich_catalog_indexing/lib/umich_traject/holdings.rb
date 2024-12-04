module Traject
  module UMich
    class Holdings
      def initialize(record, context, lib_loc_info, floor_locator, hathifiles)
        @record = record
        @context = context
        @lib_loc_info = lib_loc_info
        @floor_locator = floor_locator
        @hathifiles = hathifiles
      end

      attr_reader :context
      attr_reader :lib_loc_info

      def libLocInfo
        lib_loc_info
      end

      def enumcronSort a, b
        a[:sortstring] <=> b[:sortstring]
      end

      def enumcronSortString str
        rv = "0"
        str.scan(/\d+/).each do |nums|
          rv += nums.size.to_s + nums
        end
        rv
      end

      def sortItems(arr)
        # Only one? Never mind
        return arr if arr.size == 1

        # First, add the _sortstring entries
        arr.each do |h|
          # if h.has_key? 'description'
          h[:sortstring] = if h[:description]
            enumcronSortString(h[:description])
          else
            "0"
          end
        end

        # Then sort it
        arr.sort! { |a, b| enumcronSort(a, b) }

        # Then remove the sortstrings
        arr.each do |h|
          h.delete(:sortstring)
        end
        arr
      end

      def run
        locations = []
        inst_codes = []
        sh = {}
        has_e56 = false
        hol_list = []

        record_has_finding_aid = false
        @record.each_by_tag("866") do |f|
          hol_mmsid = f["8"]
          next if hol_mmsid.nil?
          sh[hol_mmsid] = [] unless sh[hol_mmsid]
          sh[hol_mmsid] << f["a"]
        end
        electronic_holdings = e56.map do |field|
          ElectronicHolding.new(field)
        end
        electronic_holdings.each do |holding|
          hol_list << holding.to_h
          locations << holding.library
          inst_codes.concat(holding.institution_codes)
        end
        has_e56 = true unless electronic_holdings.empty?

        # check 856 fields:
        #   -finding aids
        #   -passwordkeeper records
        #   -other electronic resources not in alma as portfolio???
        @record.each_by_tag("856") do |f|
          next unless f["u"]
          link_text = f["y"] if f["y"]
          if (link_text =~ /finding aid/i) or !has_e56
            hol = {}
            hol[:link] = URI::DEFAULT_PARSER.escape(f["u"])
            hol[:library] = "ELEC"
            hol[:status] = f["s"] if f["s"]
            hol[:link_text] = "Available online"
            hol[:link_text] = f["y"] if f["y"]
            hol[:description] = f["3"] if f["3"]
            hol[:note] = f["z"] if f["z"]
            if link_text =~ /finding aid/i and hol[:link] =~ /umich/i
              hol[:finding_aid] = true
              record_has_finding_aid = true
              id = context.output_hash["id"]
            else
              hol[:finding_aid] = false
            end
            hol_list << hol

          end
        end
        digital_holdings = avd.map do |field|
          DigitalHolding.new(field)
        end
        digital_holdings.each do |holding|
          hol_list << holding.to_h
          locations << holding.library
          inst_codes << "MIU"
        end

        physical_holdings = physical_holding_ids.map do |id|
          PhysicalHolding.new(record: @record, holding_id: id)
        end.reject { |x| x.items.empty? }
        physical_holdings.each do |holding|
          hol_list << holding.to_h
          locations << holding.institution_code
          inst_codes << holding.institution_code
          locations.push(*holding.locations)
        end

        # add hol for HT volumes
        bib_nums = []
        bib_nums << context.output_hash["id"]&.first || ""
        bib_nums << context.output_hash["aleph_id"]&.first if context.output_hash["aleph_id"]
        oclc_nums = context.output_hash["oclc"]
        # etas_status = context.clipboard[:ht][:overlap][:count_etas] > 0
        # hf_item_list = HathiTrust::Hathifiles.get_hf_info(oclc_nums, bib_nums, etas_status)
        hf_item_list = @hathifiles.get_hf_info(oclc_nums, bib_nums)
        if hf_item_list.any?
          hf_item_list = sortItems(hf_item_list)
          hf_item_list.each do |r|
            # r[:status] = statusFromRights(r[:rights], etas_status)
            r[:status] = statusFromRights(r[:rights])
          end
          hol = {}
          hol[:library] = "HathiTrust Digital Library"
          hol[:items] = hf_item_list
          hol_list << hol

          hol[:items].each do |item|
            item[:access] = (item[:access] == 1) 	# make access a boolean
          end
        end
        {
          locations: locations,
          inst_codes: inst_codes,
          hol_list: hol_list
        }
      end

      def physical_items
        @record.find_all { |f| f.tag == "974" }
      end

      def physical_holding_ids
        physical_items.map do |h|
          h["8"]
        end.uniq.select do |h|
          @record.fields("852").any? { |f| f["8"] == h }
        end
      end

      def e56
        @e56 ||= @record.fields("E56")
      end

      def avd
        @avd ||= @record.fields("AVD")
      end

      def statusFromRights(rights, etas = false)
        # from https://github.com/hathitrust/hathifiles/blob/main/lib/item_record.rb#L24
        if /^(pdus$|pd$|world|cc|und-world|ic-world)/.match?(rights)
          "Full text"
        elsif etas
          "Full text available, simultaneous access is limited (HathiTrust log in required)"
        else
          "Search only (no full text)"
        end
      end
    end
  end
end
