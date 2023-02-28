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
      def context
        @context
      end
      def libLocInfo
        @libLocInfo
      end
      def sortItems(arr)
        # Only one? Never mind
        return arr if arr.size == 1
      
        # First, add the _sortstring entries
        arr.each do |h|
          #if h.has_key? 'description'
          if h[:description]
            h[:sortstring] = enumcronSortString(h[:description])
          else
            h[:sortstring] = '0'
          end
        end
      
        # Then sort it
        arr.sort! { |a, b| self.enumcronSort(a, b) }
      
        # Then remove the sortstrings
        arr.each do |h|
          h.delete(:sortstring)
        end
        return arr
      end
      def run

        locations = Array.new()
        inst_codes = Array.new()
        availability = Array.new()
        sh = Hash.new()
        has_e56 = false
        hol_list = Array.new()

        record_has_finding_aid = false
        @record.each_by_tag('866') do |f|
          hol_mmsid = f['8']
          next if hol_mmsid == nil
          sh[hol_mmsid] = Array.new() unless sh[hol_mmsid]
          sh[hol_mmsid] << f['a']
        end

        items = Hash.new()
        @record.each_by_tag('974') do |f|
          hol_mmsid = f['8']
          next if hol_mmsid == nil
          # timothy: need to do the equivalent of this (from getHoldings):
          #  next ITEM if $row{item_process_status} =~ /SD|CA|WN|MG|CS/;        # process statuses to ignore
          # not sure how these will manifest in the Alma extract
          #if f['y'] and f['y'] =~ /Process Status: EO/ 
          next if f['b'] == 'ELEC'		# ELEC is mistakenly migrated from ALEPH
          next if f['b'] == 'SDR'		# SDR items will be loaded from Zephir
          if f['y'] and f['y'] =~ /Process Status: (EO|SD|CA|WN|WD|MG|CS)/
            next
          end
          item = Hash.new()
          item[:barcode] = f['a']
          # b,c are current location
          item[:library] = f['b'] # current_library
          item[:location] = f['c'] # current_location
          lib_loc = item[:library]
          lib_loc = [item[:library], item[:location]].join(' ') if item[:location]
          if libLocInfo[lib_loc]
            item[:info_link] = libLocInfo[lib_loc]["info_link"]
            item[:display_name] = libLocInfo[lib_loc]["name"]
            item[:fulfillment_unit] = libLocInfo[lib_loc]["fulfillment_unit"]
          else
            item[:info_link] = nil
            item[:display_name] = lib_loc
            item[:fulfillment_unit] = "General"
          end
          item[:can_reserve] = false # default
          item[:can_reserve] = true if item[:library] =~ /(CLEM|BENT|SPEC)/
          #logge@record.info "#{id} : #{lib_loc} : #{item[:info_link]}"
          item[:permanent_library] = f['d'] # permanent_library
          item[:permanent_location] = f['e'] # permanent_collection
          if item[:library] == item[:permanent_library] and item[:location] == item[:permanent_location]
            item[:temp_location] = false
          else
            item[:temp_location] = true
          end
          item[:callnumber] = f['h']
          item[:public_note] = f['n']
          item[:process_type] = f['t']
          item[:item_policy] = f['p']
          item[:description] = f['z']
          item[:inventory_number] = f['i']
          item[:item_id] = f['7']
          items[hol_mmsid] = Array.new() if items[hol_mmsid] == nil
          items[hol_mmsid] << item
          # (not sure if this is right--still investigating in the alma publish job
          availability << 'avail_circ' if f['f'] == '1'
          locations << item[:library] if item[:library]
          locations << [item[:library], item[:location]].join(' ') if item[:location]
        end

        # get elec links for E56 fields
        @record.each_by_tag('E56') do |f|
          next unless f['u']
          hol = Hash.new()
          hol[:link] = URI.escape(f['u'])
          hol[:library] = 'ELEC'
          hol[:status] = f['s'] if f['s']
          hol[:link_text] = 'Available online'
          hol[:link_text] = f['y'] if f['y']
          hol[:description] = f['3'] if f['3']
          if f['z']
            hol[:note] = f['z']
          elsif f['n']
            hol[:note] = f['n']
          elsif f['m']
            hol[:note] = f['m']
          end
          hol[:interface_name] = f['m'] if f['m']
          hol[:collection_name] = f['n'] if f['n']
          hol[:finding_aid] = false
          hol_list << hol
          availability << 'avail_online'
          locations << hol[:library]
          sub_c_list = f.find_all {|subfield| subfield.code == 'c'}
          if sub_c_list.count == 0 or sub_c_list.count == 2 
            # no campus or both in E56--add both institutions, add UMAA to url
            inst_codes << 'MIU'
            inst_codes << 'MIFLIC'
            hol[:link].sub!("openurl", "openurl-UMAA") 
          elsif sub_c_list.count == 1 and sub_c_list.first.value == 'UMAA'
            inst_codes << 'MIU'
            hol[:link].sub!("openurl", "openurl-UMAA") 
          elsif sub_c_list.count == 1 and sub_c_list.first.value == 'UMFL'
            inst_codes << 'MIFLIC'
            hol[:link].sub!("openurl", "openurl-UMFL") 
          else 	# should't occur
            logge@record.info "#{id} : can't process campus info for E56 (#{sub_c_list})"
          end
          has_e56 = true
        end

        # check 856 fields:
        #   -finding aids
        #   -passwordkeeper records
        #   -other electronic resources not in alma as portfolio???
        @record.each_by_tag('856') do |f|
          next unless f['u']
          link_text = f['y'] if f['y']
          if (link_text =~ /finding aid/i) or !has_e56
            hol = Hash.new()
            hol[:link] = URI.escape(f['u'])
            hol[:library] = 'ELEC'
            hol[:status] = f['s'] if f['s']
            hol[:link_text] = 'Available online'
            hol[:link_text] = f['y'] if f['y']
            hol[:description] = f['3'] if f['3']
            hol[:note] = f['z'] if f['z']
            if link_text =~ /finding aid/i and hol[:link] =~ /umich/i
              hol[:finding_aid] = true
              record_has_finding_aid = true
              id = context.output_hash['id']
            else
              hol[:finding_aid] = false
            end
            availability << 'avail_online' if ['0', '1'].include?(f.indicator2)
            hol_list << hol

          end
        end

        # copy-level(one for each 852)
        @record.each_by_tag('852') do |f|
          hol_mmsid = f['8']
          next if hol_mmsid == nil
          next if f['b'] == 'ELEC'		# ELEC is mistakenly migrated from ALEPH
          next if f['b'] == 'SDR'		# SDR holdings will be loaded from Zephir
          next unless items[hol_mmsid] # might also have to check for linked records
          hol = Hash.new()
          hol[:hol_mmsid] = hol_mmsid
          hol[:callnumber] = f['h']
          hol[:library] = f['b']
          hol[:location] = f['c']
          lib_loc = hol[:library]
          lib_loc = [hol[:library], hol[:location]].join(' ') if hol[:location]
          if libLocInfo[lib_loc]
            hol[:info_link] = libLocInfo[lib_loc]["info_link"]
            hol[:display_name] = libLocInfo[lib_loc]["name"]
          else
            hol[:info_link] = nil
            hol[:display_name] = lib_loc
          end
          hol[:floor_location] = @floor_locator.resolve(hol[:library], hol[:location], hol[:callnumber]) if hol[:callnumber]
          hol[:public_note] = f['z']
          hol[:items] = sortItems(items[hol_mmsid])
          hol[:items].map do |i|
            i[:record_has_finding_aid] = record_has_finding_aid
            if i[:library] =~ /^(BENT|CLEM|SPEC)/ and record_has_finding_aid
              i[:can_reserve] = false
              #logge@record.info "#{id} : can_reserve changed to false"
            end
          end
          hol[:summary_holdings] = nil
          hol[:summary_holdings] = sh[hol_mmsid].join(' : ') if sh[hol_mmsid]
          hol[:record_has_finding_aid] = record_has_finding_aid
          hol_list << hol
          locations << f['a'].upcase if f['a']
          inst_codes << f['a'].upcase if f['a']
          locations << hol[:library] if hol[:library]
          locations << [hol[:library], hol[:location]].join(' ') if hol[:location]
        end

        # add hol for HT volumes
        bib_nums = Array.new()
        bib_nums << '.' + (context.output_hash['id']&.first || "")
        bib_nums << context.output_hash['aleph_id']&.first if context.output_hash['aleph_id']
        oclc_nums = context.output_hash['oclc']
        #etas_status = context.clipboard[:ht][:overlap][:count_etas] > 0
        #hf_item_list = HathiTrust::Hathifiles.get_hf_info(oclc_nums, bib_nums, etas_status)
        hf_item_list = @hathifiles.get_hf_info(oclc_nums, bib_nums)
        if hf_item_list.any?
          hf_item_list = sortItems(hf_item_list)
          hf_item_list.each do |r|
            #r[:status] = statusFromRights(r[:rights], etas_status)
            r[:status] = statusFromRights(r[:rights])
          end
          hol = Hash.new()
          hol[:library] = 'HathiTrust Digital Library'
          hol[:items] = hf_item_list
          hol_list << hol

          # get ht-related availability values
          availability << 'avail_ht'
          hol[:items].each do |item|
            item[:access] = (item[:access] == 1) 	# make access a boolean
            availability << 'avail_ht_fulltext' if item[:access]
            availability << 'avail_online' if item[:access]
          end
          #availability << 'avail_ht_etas' if context.clipboard[:ht][:overlap][:count_etas] > 0
        end
        [
          locations,
          inst_codes,
          availability,
          hol_list
        ]
      end
    end
  end
end
