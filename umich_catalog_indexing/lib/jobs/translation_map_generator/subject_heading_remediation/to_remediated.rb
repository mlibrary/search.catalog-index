require "marc"
module Jobs
  module TranslationMapGenerator
    module SubjectHeadingRemediation
      class ToRemediated
        class Authority
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
