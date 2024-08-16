$:.unshift "#{File.dirname(__FILE__)}/../lib"

require "traject/macros/common/subject"
extend Traject::Macros::Common::Subject

################################
######## SUBJECT / TOPIC  ######
################################

# Saving the Subject because it has some expensive operations.
each_record do |rec, context|
  context.clipboard[:subject] = Common::Subjects.new(rec)
end

to_field "topic", topics, trim_punctuation
to_field "topicStr", subject_facets, trim_punctuation

to_field "lc_subject_display", lcsh_subjects, unique
to_field "remediated_lc_subject_display", remediated_lcsh_subjects, unique
to_field "non_lc_subject_display", non_lcsh_subjects, unique

to_field "subject_browse_terms", subject_browse_subjects, unique
