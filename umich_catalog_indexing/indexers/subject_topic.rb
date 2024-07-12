$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "traject/macros/common/subject"
extend Traject::Macros::Common::Subject

################################
######## SUBJECT / TOPIC  ######
################################

# We get the full topic (LCSH), but currently want to ignore
# entries that are FAST entries (those having second-indicator == 7)

each_record do |rec, context|
  context.clipboard[:subject] = Common::Subject.new(rec)
end

skip_FAST = ->(rec, field) do
  field.indicator2 == "7" and field["2"] =~ /fast/
end

to_field "topic", topics, trim_punctuation
to_field "topicStr", subject_facets, trim_punctuation

to_field "lc_subject_display", lcsh_subjects, unique
to_field "remediated_lc_subject_display", remediated_lcsh_subjects, unique
to_field "non_lc_subject_display", non_lcsh_subjects, unique

to_field "subject_browse_terms", subject_browse_subjects, unique
