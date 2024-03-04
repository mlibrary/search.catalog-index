module Jobs
  module TranslationMapGenerator
    module SubjectHeadingRemediation
      module ToDeprecated
        class << self
          include FileWriter
          # @returns [String] name of the translation map
          def name
            "Subject Headings Deprecated to Remediated"
          end

          # @returns [String] where in the translation map directory the file
          # should go
          def file_path
            File.join("umich", "sh_remediated_to_deprecated.yaml")
          end

          # @returns [String] YAML string of translation map
          def generate
            path = File.join(S.project_root, "lib", "translation_maps", ToRemediated.file_path)
            data = YAML.load_file(path)
            reverse_it(data).to_yaml(line_width: 1000)
          end

          def reverse_it(data)
            out = Hash.new { |h, k| h[k] = [] }
            data.keys.each do |k|
              remediated_term = data[k].downcase
              out[remediated_term].push(k)
            end
            out.keys.each do |k|
              out[k] = out[k].join("||")
            end
            out
          end
        end
      end
    end
  end
end
