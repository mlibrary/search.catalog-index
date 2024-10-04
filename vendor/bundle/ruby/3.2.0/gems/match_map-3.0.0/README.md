# MatchMap -- a multimap where key matching is based on regular expressions

`match_map` defines an object with a hash-like interface that allows Regexp patterns as keys and/or multiple simultaneous lookuup arguments. Calling `mm[arg]` checks _arg_ against every key, aggregating their associated values into an array.

```ruby
require 'match_map'

mm = MatchMap.new
mm['a'] = 'a_string'
mm[/a/] = 'apat'
mm[/b/] = ['bpat1', 'bpat2']
mm[/.+b$/] = 'bpat3'

mm['a']    #=> ['a_string', 'apat'] # order is the same as the key order
mm['aa']   #=> ['apat']
mm['b']    #=> ['bpat1', 'bpat2']
mm['cob']  #=> ['bpat1', 'bpat2', 'bpat3'] # flattened one level!!!
mm['cab']  #=> ['apat', 'bpat1', 'bpat2', 'bpat3']
mm['c']    #=> [] # no match


# Change the default miss value to ease some processing forms
mm.default = []
mm['neverGonnaMatch'].each do { #never get here}

# You can also query on multiple values at once by passing an array
mm[['a', 'aa', 'b']] #=> ['a_string', 'apat', 'bpat1', 'bpat2']

# Or use a Proc as the value; it gets the match variable as its argument

mm = MatchMap.new
mm[/a(b+)/] = Proc.new {|m| [m[1].size]}
mm['abbbb'] #=> [4]


# You can set #echo to return the argument :always or only :onmiss
mm = MatchMap.new
mm[/ab/] = "AB"

# first, without echo
mm['miss'] = []
mm['cab']  = ['AB']

#...then with echo = :always
mm.echo = :always
mm['miss'] = ['miss']
mm['cab']  = ['cab', 'AB']

#...and again with echo = :onmiss
mm.echo = :onmiss
mm['miss'] #=> ['miss'] # because nothing else matched
mm['cab']  #=> ['AB']   # because a match was found

# Need to ditch a key?
if mm.has_key? /ab/ 
  mm.delete /ab/
end

```

A MatchMap is a hash-like with the following properties:

* The return value is always a (possibly empty) array
* keys can be anything that responds to '==' (e.g., strings) or regular expressions
* keys cannot be repeated (mirroring how a hash works, but see below about multiple values)
* arguments are compared to non-pattern keys based on ==
* arguments are compared to pattern keys based on pattern match against arg.to_s_
* values can be scalars, arrays (treated as multiple return values), or Proc objects
* a scalar argument to #[] is left alone for comparison to non-patterns (so a string or integer can be exactly matched), but converted to a string for comparison to patterns. (see "How are arguments compared to keys?", below)
* an array argument to #[] is treated as if you want all values for all matches for all array members
* the return value from #[] goes through #uniq and #compact (no repeated values, no nil values), which may or may not mess with what you expect the output order to be.

The idea is that you can set up a bunch of (possibly overlapping) patterns, each of which is associated with one or more values, and easily get back all the values for those patterns that match the argument. `match_map` was originally designed for transforming values for full-text indexing, but has other uses as well. 


## What is this good for?

A match_map can be useful for (among other things) values that map onto a hierarchy.

Here's part of a map for library call numbers:

```ruby
mm = MatchMap.new
mm[/^H/] = 'Social Science'
mm[/^HA/] = 'Statistics'
mm['HA37 .P27 P16'] #=> ['Social Science', 'Statistics']
```

Or use it as a clean way to extract semi-regular information from free-text strings

```ruby
state = MatchMap.new
state[/\bMN\b/i] = 'Minnesota'
state[/\bMI\b/i] = 'Michigan'
state['St. Paul, MN 55117'] #=> ['Minnesota']
state['2274 Delaware Drive, Ann Arbor, MI, 48103'] #=> ['Michigan']
```


## How are arguments compared to keys?

There are three basic rules:

1. If the argument is an array, each element is handled separately
2. If the argument (`a`) is being matched against a pattern key (`pk`), check if `pk.match(a.to_s)`
3. If the argument (`a`) is being matched against a key that is not a pattern (`npk`), check if `a == npk`

Here's a quick example to show how it works

```ruby
  mm = MatchMap.new
  mm[1] = 'fixnum'
  mm['1'] = 'string'
  mm[/1/] = 'pattern'
  mm[1] #=> ['fixnum', 'pattern']
  mm['1'] #=> ['string', 'pattern']
```


## Using Proc objects as values

You can also use a Proc object as a value. It must:

* take a single argument; the match variable (if your key was a Regexp) or the string matched
* return a (possibly empty) _array of values_

It doesn't make a lot of sense to use a Proc value if your key is just a scalar, but it's possible.

This can be abused, of course, but can be useful. Here's a simple example that reverses the order of a comma-delimited duple. 

```ruby
mm = MatchMap.new
mm[/^(.+),\s*(.+)$/] = Proc.new {|m| "#{m[2]} #{m[1]}"}
mm['Dueber, Bill'] #=> ["Bill Dueber"]
```    
## Using echo to always/sometimes get back the argument

There are two common requirements when doing this sort of translation for indexing:

* The raw argument should always appear in the output
* The raw argument should appear in the output only if there are no other matches. 

```ruby
mm = MatchMap.new
mm[/ab/] = "AB"

# first, without echo
mm['miss'] = []
mm['cab']  = ['AB']

#...then with echo = :always
mm.echo = :always
mm['miss'] = ['miss']
mm['cab']  = ['cab', 'AB']

#...and again with echo = :onmiss
mm.echo = :onmiss
mm['miss'] #=> ['miss'] # because nothing else matched
mm['cab']  #=> ['AB']   # because a match was found
```

Note that the `default` value will never be added to the output if `echo` is set.

## Optimizing

You can call `mm.optimize!` to attempt to optimize a MatchMap where none of the keys are regular expressions
and none of the values are Proc objects for a significant speed increase (run `rake bench` for an idea
of how much faster). This allows you to take advantage of all the differences between MatchMap and a regular
hash (pass multiple arguments, flatten return values, echoing, etc.) while remaining an O(1) operation (instead
of a O(n) for the standard, try-to-match-each-key-in-turn algorithm). 

Note that a call to `#optimize!` actually picks the best algorithm for that particular map, so if you have a simple map,
call `#optmize!`, and add a regular-expression key, another call to `#optmize!` is required to start using the 
regular algorithm again. 

Obviously, only call `#optimize!` when you're sure you won't be modifying the map anymore. 

## Gotchas

* Like a hash, repeated assignment to the same key results in a replacement. So `mm[/a/] = 'a'; mm[/a/] = 'A'` will give `mm['a'] #=> ['A']`
* Return values are flattened one level. So, /a/ => 1 and b => [2,3], the something that matches both will return [1,2,3]. If you really want to return an array, you need to do something like `m['a'] = [[1,2]]`
  

## Contributing to MatchMap
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 Bill Dueber. See LICENSE.txt for
further details.

