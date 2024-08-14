# frozen_string_literal: true

module Common
  class Subjects
  end
end

require_relative "subjects/lc_subject"
require_relative "subjects/non_lc_subject"
require_relative "subjects/normalize"
require_relative "subjects/subject"

module Common
  class Subjects
    # We define subjects as being in any of these fields:
    SUBJECT_FIELDS = "600 610 611 630 648 650 651 653 654 655 656 657 658 662 690"

    def initialize(record)
      @record = record
    end

    # @return [Array<String>] An array of LC subject strings
    def lc_subjects
      lc_subject_fields.map do |f|
        Subject.new(f).subject_string
      end
    end

    # @return [Array<String>] An array of non LC subject strings
    def non_lc_subjects
      (subject_fields - lc_subject_fields).map do |f|
        Subject.new(f).subject_string
      end
    end

    # Get all the subject fields including associated 880 linked fields
    #
    # @return [Array<MARC::DataField>] A (possibly empty) array of subject
    # fields and their linked counterparts, if any
    def subject_fields
      sfields = @record.select { |field| Subject.subject_field?(field) }
      sfields + sfields.flat_map { |field| _linked_fields_for(field) }.compact
    end

    # Get only the LC subject fields and any associated 880 linked fields
    #
    # @return [Array<MARC::DataField>] A (possibly empty) array of LC subject
    # fields and their linked counterparts, if any
    def lc_subject_fields
      sfields = @record.select { |field| Subject.lc_subject_field?(field) }
      sfields + sfields.flat_map { |field| _linked_fields_for(field) }.compact
    end

    # Determine the 880 (linking fields) for the given field. Should probably
    # be pulled out into a more generically-available macro
    #
    # @param [MARC::DataField] field The field you want to try to match
    # @return [Array<MARC::DataField>] A (possibly empty) array of linked fields
    def _linked_fields_for(field)
      linking_id = field["6"]
      if linking_id
        @record.fields("880").select { |eef| eef["6"]&.start_with? "#{field.tag}-#{linking_id.split("-").last}" }
      else
        []
      end
    end
  end
end
