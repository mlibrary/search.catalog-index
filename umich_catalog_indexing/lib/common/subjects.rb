# frozen_string_literal: true

module Common
  class Subjects
  end
end

require_relative "subjects/lc_subject"
require_relative "subjects/non_lc_subject"
require_relative "subjects/normalize"
require_relative "subjects/subject"
require_relative "subjects/remediation_map"
require_relative "subjects/field"

module Common
  class Subjects
    # We define subjects as being in any of these fields and subfields:
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
    REMEDIATION_MAP = RemediationMap.new

    def initialize(record)
      @record = record
    end

    # @return [Array<String>] An array of LC subject strings
    def lc_subjects
      _subject_strings(lc_subject_fields)
    end

    # @return [Array<String>] An array of non LC subject strings
    def non_lc_subjects
      _subject_strings(non_lc_subject_fields)
    end

    # @return [Array<String>] An array of all remediated LC subject strings
    def remediated_lc_subjects
      _subject_strings(remediated_lc_subject_fields)
    end

    # @return [Array<String>] An array of all subject browse strings
    def subject_browse_subjects
      _subject_strings(subject_browse_subject_fields)
    end

    def _subject_strings(fields)
      fields.map do |f|
        Subject.new(f).subject_string
      end
    end

    # Returns an array of all subject fields: given subject, remediated, and
    # deprecated This is for enabling searching on deprecated terms as well as
    # remediated terms
    #
    # @return [Array<String>] Subject facet strings
    def topics
      _facet_fields_for(
        subject_fields +
        newly_remediated_subject_fields +
        newly_deprecated_subject_fields
      )
    end

    # Returns an array of subjects that will go in the subjects facet. It
    # excludes deprecated terms so that they don't show up in the Search UI.
    #
    # @return [Array<String>] Subject facet strings
    def subject_facets
      _facet_fields_for(
        lc_subject_fields +
        non_lc_subject_fields +
        already_remediated_subject_fields +
        newly_remediated_subject_fields
      )
    end

    # Turn the subject fields into facet strings. We want the "a" subfield and
    # we want a different set of subfields depending on which tag it is. Skip
    # any fast records (second-indicator == 7)
    #
    # @param fields [Array<MARC::DataField>]
    # @return [Array[String]] Array of facet strings
    def _facet_fields_for(fields)
      fields.reject do |field|
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

    # Get all the subject fields including associated 880 linked fields
    #
    # @return [Array<MARC::DataField>] A (possibly empty) array of subject
    # fields and their linked counterparts, if any
    def subject_fields
      @subject_fields ||= begin
        sfields = @record.select { |field| Subject.subject_field?(field) }
        sfields + sfields.flat_map { |field| _linked_fields_for(field) }.compact
      end
    end

    # Get only the LC subject fields and any associated 880 linked fields. This
    # list does not include deprecated subjects.
    #
    # @return [Array<MARC::DataField>] A (possibly empty) array of LC subject
    # fields and their linked counterparts.
    def lc_subject_fields
      @lc_subject_fields ||= begin
        sfields = subject_fields.select do |field|
          Subject.lc_subject_field?(field) && !_field_inst(field).remediable?
        end
        sfields + sfields.flat_map { |field| _linked_fields_for(field) }.compact
      end
    end

    # Get the list of LC subject fields that have already been remediated or
    # have been transformed into remediated subjects
    #
    # @return [Array<MARC::DataField>] A (possibly empty) array of Subject
    # fields
    def remediated_lc_subject_fields
      already_remediated_subject_fields +
        newly_remediated_subject_fields
    end

    # Get the list of subject fields that aren't LC and aren't already
    # remediated or deprecated
    #
    # @return [Array<MARC::DataField>] A (possibly empty) array of Subject
    # fields
    def non_lc_subject_fields
      subject_fields -
        lc_subject_fields -
        remediable_subject_fields -
        already_remediated_subject_fields
    end

    # Get the list of subject fields that belong in subject browse
    #
    # @return [Array<MARC::DataField>] A (possibly empty) array of Subject
    # fields
    def subject_browse_subject_fields
      lc_subject_fields +
        newly_remediated_subject_fields +
        already_remediated_subject_fields
    end

    # Transformations of already remediated subjects fields
    #
    # @return [Array<MARC::DataField>] A (possibly empty) array of subject
    # fields that have been remediated and are now the deprecated version
    def newly_deprecated_subject_fields
      @deprecated_subject_fields ||=
        already_remediated_subject_fields.map do |field|
          _field_inst(field).to_deprecated
        end.flatten
    end

    # @return [Array<MARC::DataField>] A (possibly empty) array of subject
    # fields in the bib record that have already been remediated
    def already_remediated_subject_fields
      @already_remediated_subject_fields ||=
        (subject_fields - lc_subject_fields).filter_map do |field|
          field if _field_inst(field).already_remediated?
        end
    end

    # Transformations of deprecated subjects fields in the bib record
    #
    # @return [Array<MARC::DataField>] A (possibly empty) array of subject
    # fields
    def newly_remediated_subject_fields
      @newly_remediated_subject_fields ||=
        remediable_subject_fields.map do |field|
          _field_inst(field).to_remediated
        end
    end

    # @return [Array<MARC::DataField>] A (possibly empty) array of subject
    # fields in the bib record with deprecated subjects terms
    def remediable_subject_fields
      @remediable_subject_fields ||=
        subject_fields.filter_map do |field|
          field if _field_inst(field).remediable?
        end
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

    # @param field [MARC::DataField] Subject field for instantiating a
    # Subjects::Field object
    # @return [Subjects::Field]
    def _field_inst(field)
      _fields[field.object_id] || Field.new(field: field, remediation_map: REMEDIATION_MAP, normalized_sfs: _normalized_sfs(field))
    end

    # @return [Hash] Hash of subject field object ids and the corresponding
    # Subjects::Field object
    def _fields
      @_fields ||= subject_fields.map do |field|
        [field.object_id, Field.new(field: field, remediation_map: REMEDIATION_MAP, normalized_sfs: _normalized_sfs(field))]
      end.to_h
    end

    # @param field [MARC::DataField] Subject field
    # @return [Array<Hash>] Array of hashes that have the subfield codes and normalized version of the value.
    def _normalized_sfs(field)
      _normalized_subject_sfs_in_record[field.object_id] ||
        field.subfields.map do |sf|
          {"code" => sf.code, "value" => REMEDIATION_MAP.normalize_sf(sf.value)}
        end
    end

    # @retrun [Hash] Hash of subject field object ids and the corresponding
    # Array of normalized subfields and their codes
    def _normalized_subject_sfs_in_record
      @_normalized_subject_sfs_in_record ||= subject_fields.map do |field|
        [field.object_id, field.subfields.map do |sf|
          {"code" => sf.code, "value" => REMEDIATION_MAP.normalize_sf(sf.value)}
        end]
      end.to_h
    end
  end
end
