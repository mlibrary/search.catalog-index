module BestBets
  class Term
    def initialize(hsh = {})
      @id = hsh['tid']
      @name = hsh['category']
      @rankings = {hsh['id'] => hsh['rank']}
    end

    def merge!(hsh = {})
      return self unless hsh.has_key?('id') && hsh.has_key?('rank')
      @rankings[hsh['id']] = hsh['rank']
      self
    end

    def to_field
      @name.downcase.gsub(/[^a-z'&]/, '_').gsub(/_+/, '_').sub(/_+$/, '') + '_bb'
    end

    def marc
      "001"
    end

    def on(id)
      yield @rankings[id] if @rankings.has_key?(id) && @rankings[id]
    end
  end
end
