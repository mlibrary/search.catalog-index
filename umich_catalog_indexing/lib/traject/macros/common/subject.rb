## frozen_string_literal: true

require "common/subject"

module Traject::Macros::Common
  # Code to extract subject fields (and their string representations) from the 600-699
  # fields of a MARC record.
  module Subject
    def lcsh_subjects
      ->(record, accumulator) do
        subject_fields = Common::Subject.lc_subject_fields(record)
        subjects = subject_fields.map { |f| Common::Subject.for(f) }
        accumulator.replace subjects.map { |s| s.subject_string(" -- ") }
      end
    end

    def remediated_lcsh_subjects
      ->(record, accumulator) do
        subject_fields = Common::Subject.remediated_lc_subject_fields(record)
        subjects = subject_fields.map { |f| Common::Subject.for(f) }
        accumulator.replace subjects.map { |s| s.subject_string(" -- ") }
      end
    end

    def non_lcsh_subjects
      ->(record, accumulator) do
        subject_fields = Common::Subject.non_lc_subject_fields(record)
        subjects = subject_fields.map { |f| Common::Subject.for(f) }
        accumulator.replace subjects.map { |s| s.subject_string(" -- ") }
      end
    end

    def subject_browse_subjects
      ->(record, accumulator) do
        subject_fields = Common::Subject.subject_browse_fields(record)
        subjects = subject_fields.map { |f| Common::Subject.for(f) }
        accumulator.replace subjects.map { |s| s.subject_string }
      end
    end

    def topics
      ->(record, accumulator) do
        accumulator.replace Common::Subject.topics(record)
      end
    end

    def subject_facets
      ->(record, accumulator) do
        accumulator.replace Common::Subject.subject_facets(record)
      end
    end
  end
end
