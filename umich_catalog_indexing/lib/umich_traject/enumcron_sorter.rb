module Traject::UMich
  module EnumcronSorter
    def self.sort(arr)
      arr.sort do |a,b|
        enumcronSortString(a.description) <=> enumcronSortString(b.description)
      end
    end
    private
    def self.enumcronSortString str
      return '0' if str.nil?
      # return value; starts with 0
      rv = '0'

      #gets each group of digits
      str.scan(/\d+/).each do |nums|
        # comparison string is total_number_of_digits  + the digits
        # example: v.30:no.4 becomes 023014; 
        # 0: rv starts with 0. 
        # 2: 30 is the first group and has 2 digits. 
        # 30: is the value of the first group  
        # 1: 4 is the second group and has one digit
        # 4: is the value of the second group
        rv += nums.size.to_s + nums
      end
      return rv
    end
  end
end
