class Traject::UMich::PhysicalHoldings
  include Enumerable

  def initialize(record:, holding_ids:)
    @record = record
    @holding_ids = holding_ids
  end

  def all
    @holding_ids.map do |id|
      Traject::UMich::PhysicalHolding.for(record: @record, holding_id: id)
    end.reject { |x| x.items.empty? }
  end

  def combined
    all
  end

  def each(&block)
    combined.each do |item|
      block.call(item)
    end
  end
end
