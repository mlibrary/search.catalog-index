# frozen_string_literal: true

require "traject"

module Common
  class Subjects
  end
end

require_relative "subjects/remediation_map"
require_relative "subjects/field"
require_relative "subjects/subject"
require_relative "subjects/lc_subject"
require_relative "subjects/non_lc_subject"
require_relative "subjects/normalize"
require_relative "subjects/remediator"

module Common
  class Subjects
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
    REMEDIATION_MAP = RemediationMap.new

    REMEDIATOR = Remediator.new

    def initialize(record)
      @record = record
    end

    def subject_fields
      sfields = @record.select { |field| Subject.subject_field?(field) }
      sfields + sfields.flat_map { |field| _linked_fields_for(field) }.compact
    end

    # Get only the LC subject fields and any associated 880 linked fields
    # @param [MARC::Record] record The record
    # @return [Array<MARC::DataField>] A (possibly empty) array of LC subject fields and their
    # linked counterparts, if any
    def lc_subject_fields
      sfields = @record.select { |field| Subject.lc_subject_field?(field) }
      sfields + sfields.flat_map { |field| _linked_fields_for(field) }.compact
    end

    def non_lc_subject_fields
      subject_fields -
        lc_subject_fields -
        _remediable_subject_fields -
        already_remediated_subject_fields
    end

    def remediated_lc_subject_fields
      remediated_subject_fields +
        already_remediated_subject_fields
    end

    def already_remediated_subject_fields
      (subject_fields - lc_subject_fields).filter_map do |field|
        field if field_inst(field).already_remediated?
      end
    end

    def deprecated_subject_fields
      already_remediated_subject_fields.map do |field|
        field_inst(field).to_deprecated
      end.flatten
    end

    def remediated_subject_fields
      _remediable_subject_fields.map do |field|
        field_inst(field).to_remediated
      end
    end

    def _remediable_subject_fields
      subject_fields.filter_map do |field|
        field if field_inst(field).remediable?
      end
    end

    def _normalized_subject_subfields
      @normalized_subject_subfields ||= subject_fields.filter_map do |field|
        field.subfields.filter_map do |sf|
          {"code" => sf.code, "value" => REMEDIATOR._normalize_sf(sf.value)}
        end
      end
    end

    def subject_browse_fields
      lc_subject_fields +
        remediated_subject_fields +
        already_remediated_subject_fields
    end

    def topics
      (
        subject_fields +
        deprecated_subject_fields +
        remediated_subject_fields
      ).reject do |field|
        field.indicator2 == "7" && field["2"] =~ /fast/
      end.map do |field|
        a = field["a"]
        more = []
        field.each do |sf|
          more.push sf.value if TOPICS[field.tag]&.chars&.include?(sf.code)
        end
        [a, more.join(" ")]
      end.flatten.uniq
    end

    def subject_facets
      (
        subject_fields +
        remediated_subject_fields
      ).reject do |field|
        field.indicator2 == "7" && field["2"] =~ /fast/
      end.reject do |field|
        field_inst(field).remediable?
      end.map do |field|
        unless field.indicator2 == "7" && field["2"] =~ /fast/
          a = field["a"]
          more = []
          field.each do |sf|
            more.push sf.value if TOPICS[field.tag]&.chars&.include?(sf.code)
          end
          [a, more.join(" ")]
        end
      end.flatten.uniq
    end

    # Determine the 880 (linking fields) for the given field. Should probably be pulled
    # out into a more generically-available macro
    # @param [MARC::Record] record The record
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

    def field_inst(field)
      # REMEDIATOR
      Field.new(field: field, remediation_map: REMEDIATION_MAP)
    end
  end
end
