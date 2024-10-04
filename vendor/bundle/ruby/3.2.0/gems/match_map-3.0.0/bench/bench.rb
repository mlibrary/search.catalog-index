require 'benchmark'
require 'match_map'
require 'pry'
require 'pry-nav'

h5 = {
  'a' => 'A',
  'b' => 'B',
  'c' => 'C',
  'd' => 'D',
  'e' => 'E',
  # /a/ => 'AAA'
}

@mm = MatchMap.new
h5.each_pair {|k,v| @mm[k] = v}

@mm2 = MatchMap.new()
(1..20).each do |i|
  @mm2[i] = i*2
end
# @mm2[/a/] = 'AAA'

iters = 100_000
binding.pry

puts "Testing #{iters} accesses"

method = (defined? JRUBY_VERSION) ? :bmbm : :bm
Benchmark.send(method) do |x|

  x.report('hash            ') do
    1..iters.times do
      y = h5['a']
    end
  end

  x.report('straight 5 keys ') do
    1..iters.times do
      y = @mm['a']
    end
  end
  
  x.report('optimized 5 keys') do
    @mm.optimize!
    1..iters.times do
      y = @mm['a']
    end
  end

  x.report('straight 20 keys') do
    1..iters.times do
      y = @mm2['a']
    end
  end
  
  
  x.report('optimized 20 keys') do
    @mm2.optimize!
     1..iters.times do
       y = @mm2['a']
     end
   end


end