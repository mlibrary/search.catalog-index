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
  TOPICS = {
    "600" => "abcdefghjklmnopqrstuvxyz",
    "610" => "abcdefghklmnoprstuvxyz",
    "611" => "acdefghjklnpqstuvxyz",
    "630" => "adefghklmnoprstvxyz",
    "648" => "avxyz",
    "650" => "abcdevxyz",
    "651" => "aevxyz",
    "653" => "abevyz",
    "654" => "abevyz",
    "655" => "abvxyz",
    "656" => "akvxyz",
    "657" => "avxyz",
    "658" => "ab",
    "662" => "abcdefgh",
    "690" => "abcdevxyz"
  }
  SUBJECT_FIELDS = TOPICS.keys
  REMEDIATEABLE_FIELDS = "650 651 653 654 655 656 657 658"
  SH_DEPRECATED_TO_REMEDIATED = ::Traject::TranslationMap.new("umich/sh_deprecated_to_remediated")
  SH_REMEDIATED_TO_DEPRECATED = ::Traject::TranslationMap.new("umich/sh_remediated_to_deprecated")

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

  def self.deprecated_subject_fields(record)
    already_remediated_subject_fields(record).map do |field|
      f = _clone_field(field)
      f.each do |sf|
        if ["a", "z"].any?(sf.code)
          if SH_REMEDIATED_TO_DEPRECATED[_normalize_sf(sf.value)]
            sf.value = SH_REMEDIATED_TO_DEPRECATED[_normalize_sf(sf.value)]
          end
        end
      end
      f
    end
  end

  def self.remediated_subject_fields(record)
    remediateable_subject_fields(record).map do |field|
      f = _clone_field(field)
      f.each do |sf|
        if ["a", "z"].any?(sf.code)
          if SH_DEPRECATED_TO_REMEDIATED[_normalize_sf(sf.value)]
            sf.value = SH_DEPRECATED_TO_REMEDIATED[_normalize_sf(sf.value)]
          end
        end
      end
      f.indicator2 = "7"
      f.append(MARC::Subfield.new("2", "miush"))
      f
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

  def self.non_lc_subject_fields(record)
    subject_fields(record) -
      lc_subject_fields(record) -
      remediateable_subject_fields(record) +
      remediated_subject_fields(record)
  end

  def self.subject_browse_fields(record)
    lc_subject_fields(record) +
      remediated_subject_fields(record) +
      already_remediated_subject_fields(record) 
  end

  def self.topics(record)
    (subject_fields(record) +
     deprecated_subject_fields(record) +
    remediated_subject_fields(record)).filter_map do |field|
      unless field.indicator2 == '7' and field['2'] =~ /fast/
        a = field["a"]
        more = []
        field.each do |sf|
          more.push sf.value if TOPICS[field.tag].chars.include?(sf.code)
        end
        [a, more.join(" ")]
      end
    end.flatten.uniq
  end

  def self.remediateable_subject_fields(record)
    subject_fields(record).filter_map do |field|
      field if _remediateable_subject_field?(field)
    end
  end

  def self.already_remediated_subject_fields(record)
    (subject_fields(record) - lc_subject_fields(record)).filter_map do |field|
      field if _already_remediated_subject_field?(field)
    end
  end

  def self._already_remediated_subject_field?(field)
    REMEDIATEABLE_FIELDS.include?(field.tag) &&
      ["a", "z"].any? do |x|
        SH_REMEDIATED_TO_DEPRECATED[_normalize_sf(field[x])]
      end
  end

  def self._remediateable_subject_field?(field)
    REMEDIATEABLE_FIELDS.include?(field.tag) &&
      ["a", "z"].any? do |x|
        SH_DEPRECATED_TO_REMEDIATED[_normalize_sf(field[x])]
      end
  end

  def self._normalize_sf(str)
    str&.downcase&.gsub(/[^A-Za-z0-9\s]/i, "")
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
