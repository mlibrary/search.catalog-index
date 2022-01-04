#################################
# COMMON HT STUFF
#################################

# Start off by building up a data structure representing all the 974s
# and stick it in ht_fields. Also, query the database for the print
# holdings along the way with #fill_print_holdings!
#
#
#
#
###################
# Which ht_ fields are actually used in mirlyn?
#
# Summary of below, ignoring stuff in the mock
# spectrum-json:spec/spectrum/bib_record.yml
#   * ht_id
#   * ht_searchonly
#
#  Command and output
# > for i in pride spectrum-deploy/upload/production search spectrum spectrum-config spectrum-json www.lib-solr-config; do cd /Users/dueberb/devel/search/$i; echo "$i"; git grep '\bht_'; echo -e "\n"; done
# pride
#
#
# spectrum-deploy/upload/production
# config/foci/mirlyn.yml:33:  f.search_isn.pf: issn isbn barcode lccn oclc sdrnum ctrlnum ht_id isn_related rptnum id id_int
# config/foci/mirlyn.yml:34:  f.search_isn.qf: issn isbn barcode lccn oclc sdrnum ctrlnum ht_id isn_related rptnum id id_int
# config/foci/mirlyn.yml:94:      ht_id^1
#
#
# search
#
#
# spectrum
#
#
# spectrum-config
# lib/spectrum/config/source.rb:116:        new_params[:fq] << 'ht_searchonly:false' if request.search_only?
#
#
# spectrum-json
# spec/spectrum/bib_record.yml:114:      ht_availability:
#   spec/spectrum/bib_record.yml:116:      ht_availability_intl:
#   spec/spectrum/bib_record.yml:118:      ht_count: 1
# spec/spectrum/bib_record.yml:119:      ht_id:
#   spec/spectrum/bib_record.yml:121:      ht_id_display:
#   spec/spectrum/bib_record.yml:123:      ht_id_update:
#   spec/spectrum/bib_record.yml:125:      ht_rightscode:
#   spec/spectrum/bib_record.yml:127:      ht_json: '[{"htid":"mdp.39015021080281","ingest":"20161130","rights":"ic","heldby":[],"collection_code":"aael"}]'
# spec/spectrum/bib_record.yml:153:      ht_searchonly: false
# spec/spectrum/bib_record.yml:154:      ht_searchonly_intl: false
#
#
# www.lib-solr-config


each_record do |r, context|

  itemset = HathiTrust::Traject::ItemSet.new
  context.clipboard[:ht][:items] = itemset

  r.each_by_tag('974') do |f|
    itemset.add HathiTrust::Traject::Item.new_from_974(f) if f['u']
  end

  context.clipboard[:ht][:has_items] = (itemset.size > 0)

end

# make use of the HathiTrust::ItemSet object stuffed into
# [:ht][:items] to pull out all the other stuff we need.

# Mirlyn doesn't need heldby!!!
# to_field 'ht_heldby' do |record, acc, context|
#   acc.concat context.clipboard[:ht][:items].print_holdings if context.clipboard[:ht][:has_items]
# end

# timothy: if these are still needed, they should be calculated from the hol hathitrust entry
to_field 'ht_availability' do |record, acc, context|
  acc.concat context.clipboard[:ht][:items].us_availability if context.clipboard[:ht][:has_items]
end

to_field 'ht_availability_intl' do |record, acc, context|
  acc.concat context.clipboard[:ht][:items].intl_availability if context.clipboard[:ht][:has_items]
end

to_field 'ht_count' do |record, acc, context|
  acc << context.clipboard[:ht][:items].size if context.clipboard[:ht][:has_items]
end



#to_field 'ht_id' do |record, acc, context|
#  acc.concat context.clipboard[:ht][:items].ht_ids if context.clipboard[:ht][:has_items]
#end

#to_field 'ht_id_display' do |record, acc, context|
#  context.clipboard[:ht][:items].each do |item|
#    acc << item.display_string
#  end
#end

#to_field 'ht_id_update' do |record, acc, context|
#  acc.concat context.clipboard[:ht][:items].last_update_dates if context.clipboard[:ht][:has_items]
#  acc.delete_if { |x| x.empty? }
#end


#to_field 'ht_rightscode' do |record, acc, context|
#  acc.concat context.clipboard[:ht][:items].rights_list if context.clipboard[:ht][:has_items]
#end


#to_field 'htsource' do |record, acc, context|
#  cc_to_of = Traject::TranslationMap.new('ht/collection_code_to_original_from')
#  acc.concat context.clipboard[:ht][:items].collection_codes.map { |x| cc_to_of[x] } if context.clipboard[:ht][:has_items]
#end

