module Jobs
  module TranslationMapGenerator
    module SubjectHeadingRemediation
      class << self
        include FileWriter
        def name
          "Subject Headings mapping"
        end

        # @returns [String] where in the translation map directory the file
        # should go
        def file_path
          File.join("umich", "subject_heading_remediation.json")
        end

        # @returns [String] JSON string of mapping
        def generate
          JSON.pretty_generate(Set.for(S.subject_heading_remediation_set_id).to_a)
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

        def to_a
          authority_records.map { |x| x.to_h }
        end
      end

      class Authority
        SUBFIELDS = ["a", "v", "x", "y", "z"]
        def self.for(authority_record_id)
          resp = AlmaRestClient.client.get("bibs/authorities/#{authority_record_id}", query: {view: "full"})
          raise StandardError, "Couldn't retrieve authority data for #{authority_record_id}" if resp.status != 200
          new(resp.body)
        end

        def initialize(data)
          @record = MARC::XMLReader.new(StringIO.new(data["anies"]&.first)).first
        end

        def remediated_term
          out_hash = Hash.new { |h, key| h[key] = [] }
          @record.fields("150").first.subfields.each do |sf|
            out_hash[sf.code].push(sf.value) if SUBFIELDS.include?(sf.code)
          end
          out_hash
        end

        def deprecated_terms
          @record.fields("450").map do |field|
            out_hash = Hash.new { |h, key| h[key] = [] }
            field.subfields.each do |sf|
              out_hash[sf.code].push(sf.value) if SUBFIELDS.include?(sf.code)
            end
            out_hash
          end.sort do |a, b|
            b.keys.count <=> a.keys.count
          end
        end

        def to_h
          {
            "150" => remediated_term,
            "450" => deprecated_terms
          }
        end
      end
    end
  end
end
