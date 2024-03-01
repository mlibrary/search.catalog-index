require "marc"
module Jobs
  module TranslationMapGenerator
    module SubjectHeadingRemediation
      module ToRemediated
        class << self
          include FileWriter
          # @returns [String] name of the translation map
          def name
            "Subject Headings Deprecated to Remediated"
          end

          # @returns [String] where in the translation map directory the file
          # should go
          def file_path
            File.join("umich", "sh_deprecated_to_remediated.yaml")
          end

          # @returns [String] YAML string of translation map
          def generate
            Set.for(S.subject_heading_remediation_set_id).to_h.to_yaml(line_width: 1000)
          end
        end
        class Set
          def self.for(id)
            resp = AlmaRestClient.client.get_all(url: "conf/sets/#{id}/members", record_key: "members")
            raise StandardError, "Couldn't retrieve authority set data for #{id}" if resp.status != 200
            new(resp.body)
          end

          def initialize(data)
            @data = data
          end

          def ids
            @data["member"].map { |x| x["id"] }
          end

          def authority_records
            ids.map do |id|
              Authority.for(id)
            end
          end

          def to_h
            authority_records.map { |x| x.to_h }.inject(:merge)
          end
        end

        class Authority
          def self.for(authority_record_id)
            resp = AlmaRestClient.client.get("bibs/authorities/#{authority_record_id}", query: {view: "full"})
            raise StandardError, "Couldn't retrieve authority data for #{authority_record_id}" if resp.status != 200
            new(resp.body)
          end

          def initialize(data)
            @record = MARC::XMLReader.new(StringIO.new(data["anies"]&.first)).first
          end

          def remediated_term
            @record["150"]["a"]
          end

          def deprecated_terms
            ["450", "550"].map do |tag|
              @record.fields(tag).map do |field|
                field["a"]
              end
            end.flatten.uniq
          end

          def to_h
            deprecated_terms.map do |term|
              [term.downcase, remediated_term.downcase]
            end.to_h
          end
        end
      end
    end
  end
end
