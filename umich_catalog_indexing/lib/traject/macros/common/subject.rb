## frozen_string_literal: true

require "common/subjects"

module Traject::Macros::Common
  # Code to extract subject fields (and their string representations) from the 600-699
  # fields of a MARC record.
  module Subject
    def lcsh_subjects
      ->(record, accumulator) do
        accumulator.replace Common::Subjects.new(record).lc_subjects
      end
    end

    def remediated_lcsh_subjects
      ->(record, accumulator) do
        accumulator.replace Common::Subjects.new(record).remediated_lc_subjects
      end
    end

    def non_lcsh_subjects
      ->(record, accumulator) do
        accumulator.replace Common::Subjects.new(record).non_lc_subjects
      end
    end

    def subject_browse_subjects
      ->(record, accumulator) do
        accumulator.replace Common::Subjects.new(record).subject_browse_subjects
      end
    end

    def topics
      ->(record, accumulator) do
        accumulator.replace Common::Subjects.new(record).topics
      end
    end

    def subject_facets
      ->(record, accumulator) do
        accumulator.replace Common::Subjects.new(record).subject_facets
      end
    end
  end
end
