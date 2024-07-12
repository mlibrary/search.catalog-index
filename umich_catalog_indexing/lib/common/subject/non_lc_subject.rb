# frozen_string_literal: true

require_relative "lc_subject"

module Common
  class Subject
    # According to the LC docs, non-LC subjects follow the same formatting and data
    # standards as LC, so this needs not do anything special until we learn otherwise.
    class NonLCSubject < Common::Subject::LCSubject
      # Here for testing purposes to distinguish from the LC subjects
      # @return [Boolean]
      def lc_subject_field?
        false
      end
    end
  end
end
