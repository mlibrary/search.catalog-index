require 'umich_traject'


###Date the record was added to the catalog####
# cat_date -- first few digits of the 006 field
# the acc.replace line is there because sometimes there are multiple
# 008 fields and that messes stuff up. example: 99187608751706381 
# from 2022-10-14

to_field 'cat_date', extract_marc('008[00-05]') do |rec, acc, context|
  acc.map! do |str| 
    begin
      Date.parse(str).strftime("%Y%m%d") 
    rescue
      '00000000'
    end 
  end
  acc.replace [acc.max]
end


#### Fund that was used to pay for it ####

to_field 'fund', extract_marc('949a')
to_field 'fund_display' do |rec, acc|
  acc.concat Traject::MarcExtractor.cached('949ad', :separator => ' - ').extract(rec)
end
to_field 'bookplate', extract_marc('949a', :translation_map => "umich/bookplates")

### mrio: updated Feb 2022
to_field 'preferred_citation', extract_marc('524a')
to_field 'location_of_originals', extract_marc('535')
to_field 'funding_information', extract_marc('536a')
to_field 'source_of_acquisition', extract_marc('541a')
to_field 'map_scale', extract_marc('255a')

###---end Feb 2022 update###
#
to_field 'content_advice'  do |rec, acc|
  advice = rec.fields("520").select{|x| x.indicator1 == "4"}.map{|x| x.value}
  acc.replace advice
end


##### Location ####

#to_field 'institution', extract_marc('971a', :translation_map => 'umich/institution_map')
#MIU, MIU-C, MIU-H, MIFLIC
#inst_map = Traject::TranslationMap.new('umich/institution_map')
#to_field 'institution', extract_marc('958a') do |rec, acc, context|
#  acc << 'MiU' if context.clipboard[:ht][:record_source] == 'zephir'   # add MiU as an institution for zephir records
#  acc.map! { |code| inst_map[code.strip] }
#  acc.flatten!
#  acc.uniq!
#end

building_map = Traject::UMich.building_map
to_field 'building', extract_marc('852bc:971a') do |rec, acc|
  acc.map! { |code| building_map[code.strip] }
  acc.flatten!
  acc.uniq!
end


# Apply Best Bets
require 'best_bets'

BestBets.load('https://apps.lib.umich.edu/admin/bestbets/export').each_term do |term|
  to_field(term.to_field) do |rec, acc|
    term.on(rec[term.marc].value) do |rank|
      acc << rank
    end
  end
end


# UMich-specific stuff based on Hathitrust. For Mirlyn, we say something is
# htso iff it has no ht fulltext, and no other holdings. Basically, this is
# the "can I somehow get to the full text of this without resorting to
# ILL" field in Mirlyn


# An item in Mirlyn is search only if
#  - there's no HT fulltext
#  - there's no other physical or electronic holdings


# First we'll figure out whether we have holdings
F973b = Traject::MarcExtractor.cached('973b')
F852b = Traject::MarcExtractor.cached('852b')

each_record do |rec, context|
  has_non_ht_holding = false

  F973b.extract(rec).each do |val|
    has_non_ht_holding = true if ['avail_online', 'avail_circ'].include? val
  end

  F852b.extract(rec).each do |val|
    has_non_ht_holding = true unless val == 'SDR'
  end

  context.clipboard[:ht][:has_non_ht_holding] = has_non_ht_holding
end


to_field 'ht_searchonly' do |record, acc, context|
  has_ht_fulltext = context.clipboard[:ht][:items]&.us_fulltext? || false
  if has_ht_fulltext or context.clipboard[:ht][:has_non_ht_holding] or context.clipboard[:ht][:record_source] == 'alma'
    acc << false
  else
    acc << true
  end
end

to_field 'ht_searchonly_intl' do |record, acc, context|
  has_ht_fulltext = context.clipboard[:ht][:items]&.intl_fulltext? || false
  if has_ht_fulltext or context.clipboard[:ht][:has_non_ht_holding]
    acc << false
  else
    acc << true
  end
end


#### Availability ####
#
to_field 'availability', extract_marc('973b', :translation_map => 'umich/availability_map_umich')
