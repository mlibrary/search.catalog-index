module Traject
  module UMich
    class Holdings
      def initialize(record, context, libLocInfo, floor_locator, hathifiles)
        @record = record
        @context = context
        @libLocInfo = libLocInfo
        @floor_locator = floor_locator
        @hathifiles = hathifiles
      end

      attr_reader :context

      attr_reader :libLocInfo

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
        availability = []
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

        # get elec links for E56 fields
        @record.each_by_tag("E56") do |f|
          next unless f["u"]
          hol = {}
          hol[:link] = URI::DEFAULT_PARSER.escape(f["u"])
          hol[:library] = "ELEC"
          hol[:status] = f["s"] if f["s"]
          hol[:link_text] = "Available online"
          hol[:link_text] = f["y"] if f["y"]
          hol[:description] = f["3"] if f["3"]
          if f["z"]
            hol[:note] = f["z"]
          elsif f["n"]
            hol[:note] = f["n"]
          elsif f["m"]
            hol[:note] = f["m"]
          end
          hol[:interface_name] = f["m"] if f["m"]
          hol[:collection_name] = f["n"] if f["n"]
          hol[:finding_aid] = false
          hol_list << hol
          availability << "avail_online"
          locations << hol[:library]
          sub_c_list = f.find_all { |subfield| subfield.code == "c" }
          if sub_c_list.count == 0 or sub_c_list.count == 2
            # no campus or both in E56--add both institutions, add UMAA to url
            inst_codes << "MIU"
            inst_codes << "MIFLIC"
            hol[:link].sub!("openurl", "openurl-UMAA")
          elsif sub_c_list.count == 1 and sub_c_list.first.value == "UMAA"
            inst_codes << "MIU"
            hol[:link].sub!("openurl", "openurl-UMAA")
          elsif sub_c_list.count == 1 and sub_c_list.first.value == "UMFL"
            inst_codes << "MIFLIC"
            hol[:link].sub!("openurl", "openurl-UMFL")
          else 	# should't occur
            logger @record.info "#{id} : can't process campus info for E56 (#{sub_c_list})"
          end
          has_e56 = true
        end

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
            availability << "avail_online" if ["0", "1"].include?(f.indicator2)
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
          availability << "avail_online"
        end

        physical_holdings = physical_holding_ids.map do |id|
          PhysicalHolding.new(record: @record, holding_id: id)
        end.reject { |x| x.items.empty? }
        physical_holdings.each do |holding|
          hol_list << holding.to_h
          locations << holding.institution_code
          inst_codes << holding.institution_code
          locations.push(*holding.locations)
          availability << "avail_circ" if holding.circulating?
        end

        # add hol for HT volumes
        bib_nums = []
        bib_nums << "." + (context.output_hash["id"]&.first || "")
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

          # get ht-related availability values
          availability << "avail_ht"
          hol[:items].each do |item|
            item[:access] = (item[:access] == 1) 	# make access a boolean
            availability << "avail_ht_fulltext" if item[:access]
            availability << "avail_online" if item[:access]
          end
          # availability << 'avail_ht_etas' if context.clipboard[:ht][:overlap][:count_etas] > 0
        end
        {
          locations: locations,
          inst_codes: inst_codes,
          availability: availability,
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

      def avd
        @avd ||= @record.fields("AVD")
      end

      def statusFromRights(rights, etas = false)
        status = if /^(pd|world|cc|und-world|ic-world)/.match?(rights)
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
