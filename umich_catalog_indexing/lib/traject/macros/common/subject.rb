## frozen_string_literal: true

require "common/subjects"

module Traject::Macros::Common
  # Code to extract subject fields (and their string representations) from the 600-699
  # fields of a MARC record.
  module Subject
    def lcsh_subjects
      ->(record, accumulator, context) do
        # subject_fields = Common::Subject.lc_subject_fields(record)
        subject_fields = context.clipboard[:subject].lc_subject_fields
        subjects = subject_fields.map { |f| Common::Subjects::Subject.new(f) }
        accumulator.replace subjects.map { |s| s.subject_string(" -- ") }
      end
    end

    def remediated_lcsh_subjects
      ->(record, accumulator, context) do
        subject_fields = context.clipboard[:subject].remediated_lc_subject_fields
        subjects = subject_fields.map { |f| Common::Subjects::Subject.new(f) }
        accumulator.replace subjects.map { |s| s.subject_string(" -- ") }
      end
    end

    def non_lcsh_subjects
      ->(record, accumulator, context) do
        subject_fields = context.clipboard[:subject].non_lc_subject_fields
        subjects = subject_fields.map { |f| Common::Subjects::Subject.new(f) }
        accumulator.replace subjects.map { |s| s.subject_string(" -- ") }
      end
    end

    def subject_browse_subjects
      ->(record, accumulator, context) do
        subject_fields = context.clipboard[:subject].subject_browse_fields
        subjects = subject_fields.map { |f| Common::Subjects::Subject.new(f) }
        accumulator.replace subjects.map { |s| s.subject_string }
      end
    end

    def topics
      ->(record, accumulator, context) do
        accumulator.replace context.clipboard[:subject].topics
      end
    end

    def subject_facets
      ->(record, accumulator, context) do
        accumulator.replace context.clipboard[:subject].subject_facets
      end
    end
  end
end
