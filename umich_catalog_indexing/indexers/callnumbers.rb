# frozen_string_literal: true

##########################################
#
# Callnumbers
#
##########################################
# We're going to end up with the following fields:
#   * _callnumber_: Anything from an 852. These are "our" callnumbers
#   * _callnunmber_browse_: strings suitable for the callnumber browse index.
#     This includes any 852 LC or Dewey. If neither of those are found,
#     put in an 050 LC if available.
#   * _callnosort_: primary sort key for callnumbers. Since each record can
#     have only one sort key, we prioritize 852LC, then 852Dewey
#   * callnumber_secondary_sort: If there's not an 852 LC or Dewey,
#     populate this field with whatever we've got in the first 852 on the
#     record, or an 050 as a last resort. Should be empty for any record
#     with an 852LC or Dewey
#   * _callnoletters_: The letter portion from the first LC callnumber
#     found. Not used in search.

##########################################
# Helpers
##########################################

# regexs are inline because of weird jruby multithreading errors. I think.

def looks_like_lc?(str)
  re = /\A\s*\p{L}{1,3}\s*\d/ # 1-3 letters, digit
  re.match?(str)
end

def looks_like_dewey?(str)
  re = /\A\s*\d{3}\s*\.\d/ # 3 digits, dot, digit
  re.match?(str)
end

##########################################
# Standalone extractors
##########################################

# We want the 050 for LC callnumbers if we don't have another LC, but want to keep them
# separate so we always get a sort value from the 852

lc_852_extractor    = Traject::MarcExtractor.cached('852|0*|h', { alternate_script: false })
dewey_852_extractor = Traject::MarcExtractor.cached('852|1*|h', { alternate_script: false })
lc_050_extractor    = Traject::MarcExtractor.cached('050ab', { alternate_script: false })

####################################################
# Puts values by tag on the clipboard for later use
####################################################

each_record do |rec, context|
  context.clipboard['callnumbers'] = {
    lc_852:    lc_852_extractor.extract(rec).flatten.compact.uniq.select { |cn| looks_like_lc?(cn) },
    dewey_852: dewey_852_extractor.extract(rec).flatten.compact.uniq.select { |cn| looks_like_dewey?(cn) },
    lc_050:    lc_050_extractor.extract(rec).flatten.compact.uniq.select { |cn| looks_like_lc?(cn) },
  }
end

# Unrestricted: whatever we have in an 852, put it here
to_field 'callnumber', extract_marc('852hij') do |rec, acc|
  acc.select! { |x| x =~ /\S/ }
end

# Callnumbers that are viable for use in the callnumber browse
# We'll take an LC or Dewey from the 852, or an LC from the 050
# if we've got nothing else

to_field 'callnumber_browse' do |rec, acc, context|
  cns     = context.clipboard['callnumbers']
  cns_852 = cns[:lc_852].concat(cns[:dewey_852])

  if cns_852.empty?
    acc.replace cns[:lc_050]
  else
    acc.replace cns_852
  end
end

# For the main sort, we'll restrict to LC/Dewey from an 852
to_field 'callnosort' do |rec, acc, context|
  lc    = context.clipboard['callnumbers'][:lc_852].first
  dewey = context.clipboard['callnumbers'][:dewey_852].first
  best  = [lc, dewey].compact.first
  acc.replace [best] if best
end

# If we don't have a valid sort key, we'll first try
# whatever we've got in the 852, followed by
# an 050 if there's nothing else.
#
# Note that this doesn't do anything if there's already a sort key
# in callnosort

to_field 'callnosort' do |rec, acc, context|
  need_sort = context.output_hash['callnosort'].nil?

  if need_sort
    any_852   = Array(context.output_hash['callnumber']).first
    any_050   = Array(context.clipboard['callnumbers'][:lc_050]).first

    best = [any_852, any_050].compact.first
    acc << best
  end
end

# The letters of the first LC we can find, for visualization on the website. Not used
# in search

def extract_letters(cn)
  return nil if cn.nil?
  m      = /\A\s*([A-Za-z]+.*\Z)/.match(cn)
  m ? m[1].upcase : nil
end

to_field 'callnoletters', extract_marc('852hij:050ab:090ab', :first => true) do |rec, acc|
  acc.select! { |cn| looks_like_lc?(cn) }
  acc.replace [extract_letters(acc.first)].compact
end
