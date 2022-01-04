require 'traject'
require_relative 'ht_dbh'
require 'sequel'

module HathiTrust

  class UmichOverlap
    DB = HathiTrust::DBH_overlap::DB
    Umich_overlap_query = DB[:overlap].select(:access)

    # I use a db driver per thread to avoid any conflicts
    def self.get_overlap(oclc_nums)
      oclc_nums = Array(oclc_nums)
      count_all = 0 
      count_etas = 0 
      if oclc_nums.any?
        Umich_overlap_query.where(oclc: oclc_nums).each do |r|
          count_all += 1
          # following line commented out--ETAS is not active as of 2021-08-21 (timothy)
          # count_etas += 1 if r[:access] == 'deny'
        end
      end

      {
        count_all: count_all,
        count_etas: count_etas
      }

    end
  end

end


