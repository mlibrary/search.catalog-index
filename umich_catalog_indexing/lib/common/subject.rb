# frozen_string_literal: true

require "traject"

module Common
  module Subject
  end
end

require_relative "subject/lc_subject"
require_relative "subject/non_lc_subject"
require_relative "subject/normalize"

module Common::Subject
  attr_accessor :sh_deprecated_to_remediated
  # We define subjects as being in any of these fields:
  SUBJECT_FIELDS = "600 610 611 630 648 650 651 653 654 655 656 657 658 662 690"
  REMEDIATEABLE_FIELDS = "650 651 653 654 655 656 657 658"
  SH_DEPRECATED_TO_REMEDIATED = ::Traject::TranslationMap.new("umich/sh_deprecated_to_remediated")

  def self.subject_field?(field)
    SUBJECT_FIELDS.include?(field.tag)
  end

  # Delegate LC determination to the class itself.
  def self.lc_subject_field?(field)
    LCSubject.lc_subject_field?(field)
  end

  # Determine the 880 (linking fields) for the given field. Should probably be pulled
  # out into a more generically-available macro
  # @param [MARC::Record] record The record
  # @param [MARC::DataField] field The field you want to try to match
  # @return [Array<MARC::DataField>] A (possibly empty) array of linked fields
  def self.linked_fields_for(record, field)
    linking_id = field["6"]
    if linking_id
      record.fields("880").select { |eef| eef["6"]&.start_with? "#{field.tag}-#{linking_id.split("-").last}" }
    else
      []
    end
  end

  def self.remediated_subject_fields(record)
    @remediated_subject_fields ||= subject_fields(record).filter_map do |field|
      if _remediateable_subject_field?(field)
        f = _clone_field(field)
        f.each do |sf|
          if ["a","z"].any?(sf.code)
            if SH_DEPRECATED_TO_REMEDIATED[sf.value]
              sf.value = SH_DEPRECATED_TO_REMEDIATED[sf.value]
            end
          end
        end
        f
      end
    end
  end
  # Get all the subject fields including associated 880 linked fields
  # @param [MARC::Record] record The record
  # @return [Array<MARC::DataField>] A (possibly empty) array of subject fields and their
  # linked counterparts, if any
  def self.subject_fields(record)
    sfields = record.select { |field| subject_field?(field) }
    sfields + sfields.flat_map { |field| linked_fields_for(record, field) }.compact
  end

  # Get only the LC subject fields and any associated 880 linked fields
  # @param [MARC::Record] record The record
  # @return [Array<MARC::DataField>] A (possibly empty) array of LC subject fields and their
  # linked counterparts, if any
  def self.lc_subject_fields(record)
    sfields = record.select { |field| lc_subject_field?(field) }
    sfields + sfields.flat_map { |field| linked_fields_for(record, field) }.compact
  end

  def self._remediateable_subject_field?(field)
    REMEDIATEABLE_FIELDS.include?(field.tag) &&
      ["a", "z"].any? do |x|
        SH_DEPRECATED_TO_REMEDIATED[field[x]]
      end
  end

  def self._clone_field(field)
    sfields = field.subfields.map do |sf|
      MARC::Subfield.new(sf.code, sf.value)
    end
    MARC::DataField.new(field.tag, field.indicator1, field.indicator2, *sfields)
  end

  # Pass off a new subject to the appropriate class
  def self.new(field)
    if lc_subject_field?(field)
      LCSubject.from_field(field)
    else
      NonLCSubject.new(field)
    end
  end
end
