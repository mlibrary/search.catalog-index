module Jobs
  module ZephirProcessing
    class Overlap
      def self.umich_oclc_nums(zephir_nums)
        matches = S.overlap_db[:overlap].select(:oclc).where(oclc: zephir_nums).all
        zephir_nums.select do |znum|
          matches.any? do |overlap_row|
            overlap_row[:oclc] == znum
          end
        end
      end
    end
  end
end
