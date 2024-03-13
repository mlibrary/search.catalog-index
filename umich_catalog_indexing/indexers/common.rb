$:.unshift "#{File.dirname(__FILE__)}/../lib"
require "traject"
require "benchmark"

#######  COMMON STUFF BETWEEN UMICH AND HT ########
#######  INDEXING                          ########

################################
###### BOOKKEEPING #############
################################

today = DateTime.now.strftime "%Y%m%d"

# Add the base filename
to_field "input_file_name" do |rec, acc|
  mf = ENV["multifile.filename"]
  acc << Pathname.new(mf).basename if mf
end

# what day was it actually indexed?
to_field "indexing_date" do |rec, acc|
  acc << today
end

################################
###### CORE FIELDS #############
################################

to_field "id", record_id
to_field "oclc", oclcnum("035a:035z")

sdr_pattern = /^sdr-/
to_field "sdrnum" do |record, acc|
  oh35a_spec = Traject::MarcExtractor.cached("035a")
  acc.concat oh35a_spec.extract(record).grep(sdr_pattern)
end

to_field "record_source", record_source 	# set to alma or zephir, based on record id

talk_to_overlap = []
# for zephir records, check umich print holdings overlap file--skip if oclc number is found in file
each_record do |rec, context|
  # context.clipboard[:ht][:overlap] = UmichOverlap.get_overlap(oclc_nums) 	# returns count of all records found (:count_all), and access=deny records (:count_etas)
  if context.clipboard[:ht][:record_source] == "zephir"
    id = context.output_hash["id"]
    if record_is_umich(rec, context)
      context.skip!("#{id} : zephir record skipped, HOL")
    else
      # Since ETAS is not in effect, following only needed for zephir records
      oclc_nums = context.output_hash["oclc"]
      b = Benchmark.realtime do
        context.clipboard[:ht][:overlap] = UmichOverlap.get_overlap(oclc_nums) 	# returns count of all records found (:count_all), and access=deny records (:count_etas)
      end
      talk_to_overlap.push(b)
      if context.clipboard[:ht][:overlap][:count_all] > 0
        context.skip!("#{id} : zephir record skipped, overlap")
      end
    end
  end
end

after_processing do
  S.logger.info "avg time talking to overlap: #{talk_to_overlap.sum(0.0) / talk_to_overlap.size * 1000}"
end

def record_is_umich(r, context)
  return true if r["HOL"]["c"] == "MIU"			# umich record is preferred record
  context.output_hash["sdrnum"].each do |num|		# check for umich sdrnum
    return true if num.match?(/^sdr-miu/i)
  end
  false
end

to_field "allfields", extract_all_marc_values(to: "850") do |r, acc|
  acc.replace [acc.join(" ")] # turn it into a single string
end

# to_field 'fullrecord', macr4j_as_xml

to_field "fullrecord" do |rec, acc|
  # these fields are present in zephir records and cause problems in specptrum
  fields_to_delete = rec.find_all { |field| field.tag =~ /^(FMT|HOL|CAT|CID|DAT)/ }
  fields_to_delete.each do |field|
    rec.fields.delete(field)
  end
  acc << MARC::FastXMLWriter.single_record_document(rec)
end

to_field "format", umich_format_and_types

################################
######## IDENTIFIERS ###########
################################

to_field "isbn", extract_marc("020az", separator: nil) do |rec, acc|
  orig = acc.dup
  acc.map! { |x| StdNum::ISBN.allNormalizedValues(x) }
  acc << orig
  acc.flatten!
  acc.uniq!
end

to_field "issn", extract_marc("022a:022l:022m:022y:022z:247x")
to_field "isn_related", extract_marc("400x:410x:411x:440x:490x:500x:510x:534xz:556z:581z:700x:710x:711x:730x:760x:762x:765xz:767xz:770xz:772x:773xz:774xz:775xz:776xz:777x:780xz:785xz:786xz:787xz")

to_field "sudoc", extract_marc("086az")

# Aleph will s/\s/^/ in the 010 the same way they do in the control fields
# The fix *should* be in the alephsequential reader, but since ^ isn't a valid
# character in an lccn anyway, let's do it here.
to_field "lccn", extract_marc("010a") do |rec, acc|
  acc.map! { |x| x.strip }
  acc.map! { |x| x.tr("^", " ") }
end

to_field "rptnum", extract_marc("088a")

to_field "barcode", extract_marc("974a")

################################
######### AUTHOR FIELDS ########
################################

# Naconormalizer for author, only under jruby
if defined? JRUBY_VERSION
  require "naconormalizer"
  author_normalizer = NacoNormalizer.new
else
  author_normalizer = nil
end

# We need to skip all the 710 with a $9 == 'WaSeSS'

skipWaSeSS = ->(rec, field) { field.tag == "710" and field["9"] =~ /WaSeSS/ }

to_field "mainauthor", extract_marc("100abcd:110abcd:111abc")
to_field "mainauthor_role", extract_marc("100e:110e:111e", trim_punctuation: true)
to_field "mainauthor_role", extract_marc("1004:1104:1114", translation_map: "ht/relators")

to_field "author", extract_marc_unless("100abcdjq:110abcd:111acden:700abcdjq:710abcd:711acden", skipWaSeSS)
to_field "author2", extract_marc_unless("110ab:111ab:700abcd:710ab:711ab", skipWaSeSS)
to_field "author_top", extract_marc_unless("100abcdefgjklnpqtu0:110abcdefgklnptu04:111acdefgjklnpqtu04:700abcdejqux034:710abcdeux034:711acdegjnqux034:720a:765a:767a:770a:772a:774a:775a:776a:777a:780a:785a:786a:787a:245c", skipWaSeSS)
to_field "author_rest", extract_marc("505r")

to_field "authorSort", extract_marc_unless("100abcd:110abcd:111abc:110ab:700abcd:710ab:711ab", skipWaSeSS, first: true) do |rec, acc, context|
  if author_normalizer
    acc.map! { |a| author_normalizer.normalize(a) }
  end
  acc.compact!
end

# For browse entries, we only want the 100/110/111 and their 7xx counterparts
# The 1XX fields are easy and normal
to_field "author_browse_terms", extract_marc_unless(
  "100abcdjq:110abcd:111acden",
  skipWaSeSS
)

# Add on to the author_browse_terms field with the 7XXs
# The 7XXs are more complicated. Per Leigh Billings:
# 1xx fields
# AND 700*_ without a $t
# AND 700*2 with a $t [but only use the subfields abcdgq from that string in order to leave the title-related subfields out

author_7xx = Traject::MarcExtractor.cached("700abcdgq:710abcd:711acden")
def valid_author_700?(field)
  ind2_blank = [" ", "", nil].include? field.indicator2
  ind2_2 = field.indicator2 == "2"
  has_t = !field["t"].nil?
  (ind2_blank and !has_t) or (ind2_2 and has_t)
end
to_field "author_browse_terms" do |rec, acc, _context|
  authors = []
  author_7xx.each_matching_line(rec) do |field, spec, extractor|
    if valid_author_700?(field)
      authors << extractor.collect_subfields(field, spec)
    end
  end
  acc.replace authors.flatten.compact
end

# changes by mrio Feb 2022
to_field "main_author_display", extract_marc("100abcdefgjklnpqtu4:101abcdefgjklnpqtu4:110abcdefgjklnpqtu4:111abcdefgjklnpqtu4")
to_field "main_author", extract_marc("100abcdgjkqu:101abcdgjkqu:110abcdgjkqu:111abcdgjkqu")

# TODO: Change traject to allow, e.g., 700|*[^ ]abc where brackets indicate a regex
skip_non_space_indicator_2 = ->(rec, field) { field.indicator2 != " " }
skip_analytical_entry_or_title = ->(rec, field) { field.indicator2 == "2" || !field["t"].nil? }
skip_analytical_entry_or_no_title = ->(rec, field) { field.indicator2 == "2" || field["t"].nil? }

to_field "contributors_display", extract_marc_unless(["700", "710", "711"].map { |x| "#{x}abcdefgjklnpqu4" }.join(":"), skip_analytical_entry_or_title)
to_field "contributors", extract_marc_unless(["700", "710", "711"].map { |x| "#{x}abcdgjkqu" }.join(":"), skip_analytical_entry_or_title)

to_field "related_title", extract_marc_unless("730abcdefgjklmnopqrst", skip_non_space_indicator_2)
to_field "related_title", extract_marc_unless("700fjklmnoprst:710fjklmnoprst:711fklmnoprst", skip_analytical_entry_or_no_title)

# end of changes by mrio Feb2022

################################
########## TITLES ##############
################################

# For titles, we want with and without filing characters

to_field "title", extract_marc_filing_version("245abdefgknp", include_original: true)
to_field "title_a", extract_marc_filing_version("245a", include_original: true)
to_field "title_ab", extract_marc_filing_version("245ab", include_original: true)
to_field "title_c", extract_marc("245c")
to_field "title_common", extract_marc_filing_version("245abp", include_original: true)

to_field "vtitle", extract_marc("245abdefghknp", alternate_script: :only, trim_punctuation: true, first: true)

######################################
# title_equiv
######################################
#
# Based on communication primarily with Leigh Billings, we need to treat a whole lot
# of stuff as equivalent to title_common.
#
# 245 $abp
# 130 $apt
# 240 $ap
# 246 $abp - indicators are irrelevant (usage has changed over time)
# 247 $abp
# 505 $t - the $t should only appear if second indicator is coded 0
# 700 $t - ONLY if the second indicator is 2
# 710 $t - ONLY if the second indicator is 2
# 711 $t - ONLY if the second indicator is 2
# 730 $apt  - ONLY if the second indicator is 2
# 740 $ap
#
# Of these, the following will respond correctly to extract_marc_filing_version
#   * 130
#   * 245
#   * 240
#   * 247

to_field "title_equiv", extract_marc_filing_version("245abp:240ap:130apt:247abp", include_original: true)
to_field "title_equiv", extract_marc("246abp:505|*0|t:700|*2|t:710|*2|t:711|*2|t:730|*2|apt:740ap")

# The initital tests with title_equiv were a disaster -- the data are messy and a lot of weird records got
# elevated. Ignoring title_equiv in the title_a double-dip code below is a second
# attempt. I'm hoping to just replace title_top with title_equiv and get slightly better results.

# Messy, but let's take anything in title_ab or title_equiv out of title_a, so
# we don't double-dip and screw up relevance

each_record do |_r, context|
  oh = context.output_hash
  if oh["title_a"]
    oh["title_a"] = oh["title_a"] - Array(oh["title_ab"])
  end
end

# Sortable title
to_field "titleSort", extract_marc_filing_version("245abfknp", include_original: false), first_only

to_field "title_top", extract_marc("240adfghklmnoprs0:245abfgknps:247abfgknps:111acdefgjklnpqtu04:130adfgklmnoprst0")
to_field "title_rest", extract_marc("210ab:222ab:242abnpy:243adfgklmnoprs:246abdenp:247abdenp:700fgjklmnoprstx03:710fgklmnoprstx03:711acdefgjklnpqstux034:730adfgklmnoprstx03:740anp:765st:767st:770st:772st:773st:775st:776st:777st:780st:785st:786st:787st:830adfgklmnoprstv:440anpvx:490avx:505t")
to_field "series", extract_marc("440ap:800abcdfpqt:830ap")
to_field "series2", extract_marc("490avx")

def atoz
  ("a".."z").to_a.join("")
end
to_field "series_statement", extract_marc(["440", "800", "810", "811", "830"].map { |x| "#{x}#{atoz}" })
# Serial titles count on the format alreayd being set and having the string 'Serial' in it.

each_record do |rec, context|
  context.clipboard[:ht][:journal] = true if context.output_hash["format"].include? "Serial"
end

to_field "serialTitle" do |r, acc, context|
  if context.clipboard[:ht][:journal]
    acc.replace Array(context.output_hash["title"])
  end
end

to_field("serialTitle_ab") do |r, acc, context|
  if context.clipboard[:ht][:journal]
    acc.replace Array(context.output_hash["title_ab"])
  end
end

to_field("serialTitle_common") do |r, acc, context|
  if context.clipboard[:ht][:journal]
    acc.replace Array(context.output_hash["title_common"])
  end
end

to_field("serialTitle_equiv") do |r, acc, context|
  if context.clipboard[:ht][:journal]
    acc.replace Array(context.output_hash["title_equiv"])
  end
end

to_field("serialTitle_a") do |r, acc, context|
  if context.clipboard[:ht][:journal]
    acc.replace Array(context.output_hash["title_a"])
  end
end

to_field("serialTitle_rest") do |r, acc, context|
  if context.clipboard[:ht][:journal]
    acc.replace Array(context.output_hash["title_rest"])
  end
end

################################
######## TITLE AND AUTHOR  #####
################################
#
# Who can say "combinatorial explosion"?
#

SPACERUN = /\s+/

# Getting some stupid `org.jruby.RubyNil cannot be cast to org.jruby.RubyMatchData`
# errors which MRI seems uninterested in fixing. See https://bugs.ruby-lang.org/issues/12689
#
# "solution" is to put a level of method/proc/lamba indirection around the thing
# that's using the regexp, so here I just extracted into a method.

def uniqify_string(str)
  str.split(SPACERUN).uniq.compact.join(" ")
end

to_field("title_author") do |r, acc, context|
  authors = Array(context.output_hash["mainauthor"]).compact
  titles = Array(context.output_hash["title_common"]).compact

  authors.each do |a|
    titles.each do |t|
      acc << uniqify_string("#{a} #{t}")
    end
  end
end

###############################
#### Genre / geography / dates
###############################

to_field "genre", extract_marc("655ab")

# Look into using Traject default geo field
to_field "geographic" do |record, acc|
  marc_geo_map = Traject::TranslationMap.new("marc_geographic")
  extractor_043a = MarcExtractor.cached("043a", separator: nil)
  acc.concat(
    extractor_043a.extract(record).collect do |code|
      # remove any trailing hyphens, then map
      marc_geo_map[code.gsub(/-+\Z/, "")]
    end.compact
  )
end

to_field "era", extract_marc("600y:610y:611y:630y:650y:651y:654y:655y:656y:657y:690z:691y:692z:694z:695z:696z:697z:698z:699z")

# country from the 008; need processing until I fix the AlephSequential reader
to_field "country_of_pub" do |r, acc|
  country_map = Traject::TranslationMap.new("ht/country_map")
  if r["008"]
    [r["008"].value[15..17], r["008"].value[17..17]].each do |s|
      next unless s # skip if the 008 just isn't long enough
      country = country_map[s.gsub(/[^a-z]/, "")]
      if country
        acc << country
      end
    end
  end
end

# Also add the 752ab
to_field "country_of_pub", extract_marc("752ab")

# For the more-stringent "place_of_publication", we'll take
# only from the 008, and only those things that can be
# resolved in the current_cop or obsolete_cop translation
# maps, derived from the (misnamed) file at http://www.loc.gov/standards/codelists/countries.xml
#
# Several countries have one-letter codes that appear in character 17 of the 008
# (u=United States, c=Canada, etc.). Any hits on these (which are in the translation
# map as xxu, xxc, etc) will be listed as a two-fer:
#
#  uca => [United States, United States -- California ]
#
# Furthermore, we'll also special-case the USSR, since it doesn't so much
# exist anymore. Any three-letter code that ends in 'r' will be give
# the 'S.S.R' predicate iff the two-letter prefix doesn't exist in the
# current_cop.yaml file

to_field "place_of_publication" do |r, acc|
  current_map = Traject::TranslationMap.new("umich/current_cop")
  obs_map = Traject::TranslationMap.new("umich/obsolete_cop")

  if r["008"] and r["008"].value.size > 17
    code = r["008"].value[15..17].gsub(/[^a-z]/, " ")

    # Bail if we've got an explicit "undetermined"
    unless code == "xx "
      possible_single_letter_country_code = code[2]
      container = if possible_single_letter_country_code.nil? or possible_single_letter_country_code == " "
        nil
      else
        current_map["xx" << possible_single_letter_country_code]
      end

      pop = current_map[code]
      pop ||= obs_map[code]

      # USSR? Check for the two-value version
      if possible_single_letter_country_code == "r"
        container = "Soviet Union"
        non_ussr_country = current_map[code[0..1] << " "]
        if non_ussr_country
          acc << non_ussr_country
        end
      end

      if pop
        if container
          acc << container
          acc << "#{container} -- #{pop}" unless pop == container
        else
          acc << pop
        end
      end
    end

  end
end

# Deal with the dates

# First, find the date and put it into context.clipboard[:ht_date] for later use
each_record extract_date_into_context

# Now use that value
to_field "publishDate", get_date

def ordinalize_incomplete_year(s)
  i = s.to_s
  case i
  when /d\A1\d\Z/
    "#{i}th"
  when /\A\d?1\Z/
    "#{i}st"
  when /\A\d?2\Z/
    "#{i}nd"
  when /\A\d?3\Z/
    "#{i}rd"
  else
    "#{i}th"
  end
end

to_field "display_date" do |rec, acc, context|
  next unless context.output_hash["publishDate"]
  rd = context.clipboard[:ht][:rawdate]
  if context.clipboard[:ht][:display_date]
    acc << context.clipboard[:ht][:display_date]
  elsif context.output_hash["publishDate"].first == rd
    acc << rd
  elsif rd =~ /(\d\d\d)u/
    acc << "#{$1}0s (exact date unknown)"
  # acc << "in the #{$1}0s"
  elsif rd =~ /(\d\d)u+/
    # acc << 'in the ' + ordinalize_incomplete_year($1.to_i + 1) + " century"
    acc << ordinalize_incomplete_year($1.to_i + 1) + " century (exact date unknown)"
  elsif rd == "1uuu"
    acc << "Between 1000 and 1999 (exact date unknown)"
  elsif rd == "2uuu"
    acc << "Between 2000 and 2999 (exact date unknown)"
  end
end

to_field "publishDateRange" do |rec, acc, context|
  if context.output_hash["publishDate"]
    d = context.output_hash["publishDate"].first
    dr = HathiTrust::Traject::Macros::HTMacros.compute_date_range(d)
    acc << dr if dr
  else
    id = if context.output_hash["id"]
      context.output_hash["id"].first
    else
      "<no id in record>"
    end
    logger.debug "No valid date for record #{id}: #{rec["008"]}"
  end
end

################################
########### MISC ###############
################################

to_field "publisher", extract_marc("260b:264|*1|:533c")

# mrio: updated Feb 2022 to take out extraneous fields for 264
to_field "publisher_display", extract_marc("260abc:264|*1|abc")

# mrio: updated Feb 2022 to add "b"
to_field "edition", extract_marc("250ab")

to_field "language", marc_languages("008[35-37]:041a:041d:041e:041j")

to_field "language008", extract_marc("008[35-37]", first: true) do |r, acc|
  acc.reject! { |x| x !~ /\S/ } # ditch only spaces
  acc.uniq!
end

# extract_display_title will remove subfield h bracketed info, leaving the trailing punctuation
to_field "title_display", extract_display_title("245abcdefghijklmnopqrstuvwxyz")
