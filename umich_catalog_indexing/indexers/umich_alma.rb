require 'umich_traject'
require 'ht_traject'
#require 'ht_traject/ht_overlap.rb'
require 'json'
require 'umich_traject/floor_location.rb'

HathiFiles = if ENV['NODB']
               require 'ht_traject/no_db_mocks/ht_hathifiles'
               HathiTrust::NoDB::HathiFiles
             else
               require 'ht_traject/ht_hathifiles.rb'
               HathiTrust::HathiFiles
             end

libLocInfo = Traject::TranslationMap.new('umich/libLocInfo')

UMich::FloorLocation.configure('lib/translation_maps/umich/floor_locations.json')

# skip course reserve records 

each_record do |r, context|
  cr_pattern = /CR_RESTRICTED/
  r.each_by_tag('999') do |f|
    if f['a'] and f['a'] =~ /CR_RESTRICTED/
      id = context.output_hash['id']
      context.skip!("#{id} : Course reserve record skipped")
    end
  end
end

# 035    $a (MiU)003113534MIU01
aleph_pattern = /^\(MiU\)\d{9}MIU01$/
to_field 'aleph_id' do |record, acc, context|
  if context.clipboard[:ht][:record_source] == 'alma'
    aleph_spec = Traject::MarcExtractor.cached('035a')
    aleph_spec.extract(record).grep(aleph_pattern).each { |alephnum|
      acc << alephnum[5, 9]
      break		# single-valued field, some alma records have multiple occurrences, so only use first
    }
  end
end

cc_to_of = Traject::TranslationMap.new('ht/collection_code_to_original_from')
each_record do |r, context|

  locations = Array.new()
  inst_codes = Array.new()
  availability = Array.new()
  sh = Hash.new()
  has_e56 = false
  id = context.output_hash['id']

  # "OWN" field 
  r.each_by_tag(['958', 'OWN']) do |f|
    locations << f['a'].upcase if f['a']
    inst_codes << f['a'].upcase if f['a']
  end

  hol_list = Array.new()
  # this is ugly--needs to be refactored
  if context.clipboard[:ht][:record_source] == 'zephir'
    #cc_to_of = Traject::TranslationMap.new('ht/collection_code_to_original_from')
    # add hol for HT volumes
    items = Array.new()
    #etas_status = context.clipboard[:ht][:overlap][:count_etas] > 0 # make it a boolean
    r.each_by_tag('974') do |f|
      next unless f['u']
      item = Hash.new()
      item[:id] = f['u']
      item[:rights] = f['r']
      item[:description] = f['z']
      item[:collection_code] = f['c']
      item[:source] = cc_to_of[f['c'].downcase]
      item[:access] = !!(item[:rights] =~ /^(pd|world|ic-world|cc|und-world)/)
      #item[:status] = statusFromRights(item[:rights], etas_status)
      item[:status] = statusFromRights(item[:rights])
      items << item
    end
    if items.any?
      hol = Hash.new()
      hol[:library] = 'HathiTrust Digital Library'
      hol[:items] = sortItems(items)
      hol_list << hol
      locations << 'MiU'
      inst_codes << 'MIU'
      inst_codes << 'MIFLIC'
      # get ht-related availability values
      availability << 'avail_ht'
      hol[:items].each do |item|
        availability << 'avail_ht_fulltext' if item[:access]
        availability << 'avail_online' if item[:access]
      end
      #availability << 'avail_ht_etas' if context.clipboard[:ht][:overlap][:count_etas] > 0
    end
  else
    record_has_finding_aid = false
    r.each_by_tag('866') do |f|
      hol_mmsid = f['8']
      next if hol_mmsid == nil
      sh[hol_mmsid] = Array.new() unless sh[hol_mmsid]
      sh[hol_mmsid] << f['a']
    end

    items = Hash.new()
    r.each_by_tag('974') do |f|
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
      #logger.info "#{id} : #{lib_loc} : #{item[:info_link]}"
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
    r.each_by_tag('E56') do |f|
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
        logger.info "#{id} : can't process campus info for E56 (#{sub_c_list})"
      end
      has_e56 = true
    end

    # check 856 fields:
    #   -finding aids
    #   -passwordkeeper records
    #   -other electronic resources not in alma as portfolio???
    r.each_by_tag('856') do |f|
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
    r.each_by_tag('852') do |f|
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
      hol[:floor_location] = UMich::FloorLocation.resolve(hol[:library], hol[:location], hol[:callnumber]) if hol[:callnumber]
      hol[:public_note] = f['z']
      hol[:items] = sortItems(items[hol_mmsid])
      hol[:items].map do |i|
        i[:record_has_finding_aid] = record_has_finding_aid
        if i[:library] =~ /^(BENT|CLEM|SPEC)/ and record_has_finding_aid
          i[:can_reserve] = false
          #logger.info "#{id} : can_reserve changed to false"
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
    hf_item_list = HathiFiles.get_hf_info(oclc_nums, bib_nums)
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

  end

  context.clipboard[:ht][:hol_list] = hol_list
  context.clipboard[:ht][:availability] = availability.uniq
  context.clipboard[:ht][:locations] = locations.uniq
  context.clipboard[:ht][:inst_codes] = inst_codes.uniq

end

to_field 'hol' do |record, acc, context|
  acc << context.clipboard[:ht][:hol_list].to_json
end

to_field 'availability' do |record, acc, context|
  avail_map = Traject::TranslationMap.new('umich/availability_map_umich')
  acc.replace Array(context.clipboard[:ht][:availability].map { |code| avail_map[code] })
end

location_map = Traject::UMich.location_map
to_field 'location' do |record, acc, context|
  locations = Array(context.clipboard[:ht][:locations])
  #acc.replace locations.map { |code| location_map[code] }
  acc.replace locations
  acc.map! { |code| location_map[code.strip] }
  acc.flatten!
  acc.uniq!
end

#MIU, MIU-C, MIU-H, MIFLIC
inst_map = Traject::TranslationMap.new('umich/institution_map')
to_field 'institution' do |record, acc, context|
  inst_codes = Array(context.clipboard[:ht][:inst_codes])
  #acc << 'MiU' if context.clipboard[:ht][:record_source] == 'zephir'   # add MiU as an institution for zephir records
  acc.replace inst_codes
  acc.map! { |code| inst_map[code.strip] }
  acc.flatten!
  acc.uniq!
end

#######################################
# A-Z eJournal list
# ####################################
# filters:
#  - "location:ELEC"
#  - "format:Serial"
# Map first letter of the filing title to one of
# * A,B,...,Z
# "0-9" for digits
# "Other" for anything else
#

def ejournal?(context)
  elec = context.clipboard[:ht][:hol_list].any? { |hol| hol[:library]&.include? 'ELEC' }
  form = context.output_hash['format']
  elec and form.include?('Serial')
end

FILING_TITLE_880_extractor = Traject::MarcExtractor.new('245abdefgknp', alternate_script: :only)

def filing_titles_880(r)
  rv = []
  FILING_TITLE_880_extractor.each_matching_line(r) do |field, spec, extractor|
    str = FILING_TITLE_880_extractor.collect_subfields(field, spec).first
    rv << Traject::Macros::Marc21Semantics.filing_version(field, str, spec)
  end
  rv
end

STARTS_WITH_LATIN = /\A[\p{P}\p{Z}\p{Sm}\p{Sc}]*[\d\p{Latin}]/

def string_starts_with_latin(str)
  STARTS_WITH_LATIN.match? str
end

DOUBLE_BRACKET_TITLE = /\A.*[^\p{Latin}].*?\[\[\s*(\p{Latin}.*?)\]\]/

def latinized_in_double_brackets(str)
  return str if string_starts_with_latin(str)
  m = DOUBLE_BRACKET_TITLE.match(str)
  if m
    m[1]
  else
    nil
  end
end

AFTER_EQUAL_TITLE = /\A.*[^\p{Latin}].*?\s+=\s*(\p{Latin}.*)/

def latinized_after_equal_title(str)
  return str if string_starts_with_latin(str)
  m = AFTER_EQUAL_TITLE.match(str)
  if m
    m[1]
  else
    nil
  end
end

# Get the filing versions of the primary title and send it to solr to
# figure out where to put it in the A-Z list -- but only if it's an ejournal
#
to_field 'title_initial', extract_marc_filing_version('245abdefgknp', include_original: false),
         first_only,
         trim_punctuation do |rec, acc, context|
  if !ejournal?(context)
    acc.replace []
  else
    filing_title = acc.first
    if filing_title && !string_starts_with_latin(filing_title)
      extra_filing_title = filing_titles_880(rec).select { |t| string_starts_with_latin(t) }.first
      best_guess = latinized_in_double_brackets(filing_title) || latinized_after_equal_title(filing_title) || extra_filing_title
#      if !string_starts_with_latin(best_guess)
#        best_guess = latinized_in_double_brackets(extra_filing_title) || latinized_after_equal_title(extra_filing_title) || filing_title
#      end
      if best_guess and !best_guess.empty?
        acc.replace [best_guess]
#        logger.info "A-Z List: replaced #{context.output_hash['title_common'].first} with #{best_guess}"
      end
    end
  end
end

# sorting routine for enum/chron (description) item sort
def enumcronSort a, b
  return a[:sortstring] <=> b[:sortstring]
end

# Create a sortable string based on the digit strings present in an
# enumcron string

def enumcronSortString str
  rv = '0'
  str.scan(/\d+/).each do |nums|
    rv += nums.size.to_s + nums
  end
  return rv
end

def sortItems arr
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

