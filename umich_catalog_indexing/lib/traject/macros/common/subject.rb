## frozen_string_literal: true

require "common/subjects"

module Traject::Macros::Common
  # Code to extract subject fields (and their string representations) from the 600-699
  # fields of a MARC record.
  module Subject
    def lcsh_subjects
      ->(record, accumulator) do
        subject_fields = Common::Subjects.new(record).lc_subject_fields
        subjects = subject_fields.map { |f| Common::Subjects::Subject.new(f) }
        accumulator.replace subjects.map { |s| s.subject_string }
      end
    end

    def non_lcsh_subjects
      ->(record, accumulator) do
        subjects_obj = Common::Subjects.new(record)
        subject_fields = subjects_obj.subject_fields - subjects_obj.lc_subject_fields
        subjects = subject_fields.map { |f| Common::Subjects::Subject.new(f) }
        accumulator.replace subjects.map { |s| s.subject_string }
      end
    end
  end
end
