module BestBets
  class List

    def initialize(data)
      @terms = {}
      data.each do |row|
        (@terms[row['category']] ||= Term.new(row)).merge!(row)
        @terms[row['category']].merge!(row)
      end
    end

    def each_term
      @terms.each_value do |term|
        yield term
      end
    end

  end
end
