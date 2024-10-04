# A hash-like object that tries to match an argument against
# *all* keys (using == for non-Regexp keys and pattern matching
# for Regexp keys)

class MatchMap

  attr_accessor :default
  attr_reader   :echo
  
  def initialize(h = {}, &blk)
    @default = nil # default miss value is nil
    @attrs = {}
    
    # Set up the appripriate @map and define which inner_get to use
    # initially, the non-optimized version
    @map = {}
    define_singleton_method :inner_get, method(:normal_inner_get)
    
    # Initialize with the given hash
    h.each_pair do |k, v| 
      self[k] = v
    end  
    
    if block_given?
      blk.call(self)
    end
    
  end

  def delete key
    @map.delete(key)
  end


  def []= key, val
    @map[key] = val
    set_attrs key, val
  end

  def echo= arg
    raise RuntimeError.new, "echo value must be :onmiss or :always" unless [:onmiss, :always].include? arg
    @echo = arg
  end

  
  def set_attrs key, val
    @attrs[key] = {:regexkey => (key.is_a? Regexp), :procval => (val.is_a? Proc)}
  end

  def [] arg
    rv = []
    rv.push *arg if @echo == :always
    if arg.is_a? Array
      arg.map {|s| inner = self.inner_get(s); rv.push *inner}
    else
      inner = self.inner_get arg
      rv.push *inner
    end
    rv.uniq!
    rv.compact!
    if rv.size == 0
      if @echo == :onmiss
        return [*arg]
      else
        return [@default].compact
      end
    end
    return rv
  end

  def optimized_inner_get arg
    return [@map[arg]]
  end

  def normal_inner_get arg
    rv = []
    @map.keys.each do |k|
      if k.is_a? Regexp
        m = k.match arg.to_s
      else
        m = (k == arg) ? arg : false
      end
      if m
        v = @map[k]
        if v.is_a? Proc
          processed = v.call(m)
          rv.push *processed if processed
        else
          rv.push *v
        end
      end
    end
    return rv
  end

  def has_key? key
    @map.has_key? key
  end



  def optimize!
    singleton_class = class << self; self; end
    @map.each_pair do |k,v|
      if k.is_a? Regexp or v.is_a? Proc
        singleton_class.send(:define_method, :inner_get, method(:normal_inner_get))
        return
      end
    end
    singleton_class.send(:define_method, :inner_get, method(:optimized_inner_get))
  end

end