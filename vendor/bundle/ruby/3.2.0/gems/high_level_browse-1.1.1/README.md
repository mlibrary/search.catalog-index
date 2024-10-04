# HighLevelBrowse

Given an LC Call Number, try to get a set of academic disciplines associated with it

## Usage

```ruby

use 'high_level_browse'

# Pull a new version of the raw data from the UM website,
# transform it into something that can be quickly searched,
# and serialize it to `hlb.json.gz` in the specified directory
hlb = HighLevelBrowse.fetch_and_save(dir: '/tmp')

# ...or just grab an already fetch_and_saved copy
hlb = HighLevelBrowse.load(dir: '/tmp')

# What HLB categories is an LC Call Number in?
hlb.topics 'hc 9112.2'
# => [["Social Sciences", "Economics"],
#     ["Social Sciences", "Social Sciences (General)"]]

# ... or use the #[] shortcut syntax

hlb['NC1766 .U52 D733 2014']
# => [["Arts", "Art History"],
#    ["Arts", "Art and Design"],
#    ["Arts", "Film and Video Studies"]]

# You can also send more than one call number at a time

hlb.topics('E 99 .S2 Y67 1993', 'PS 3565 .R5734 F67 2015')
# => [["Humanities", "American Culture"],
#     ["Humanities", "United States History"],
#     ["Social Sciences", "Native American Studies"],
#     ["Social Sciences", "Archaeology"],
#     ["Humanities", "English Language and Literature"]]

```


## Overview

While we in the library world sometimes use LC Call Numbers (or at least
the initial letters) as a proxy for subject matter, the mapping is iffy
in many cases and is, in any case, one-dimensional. Many works simply
cover multiple subjects or are relevant to sometimes quite different
types of academics.

Take, for example, the chemistry of the brain as it applies to mental
illness. We have a book, _Endorphins : new waves in brain chemistry_
cataloged as **QP552.E53 D381 1984**. The QP's map to "Phsiology", which
is correct but not complete.

The University of Michigan Library has for years maintained 
the [High Level Browse](https://www.lib.umich.edu/browse/categories/) (HLB),
a mapping of call-number ranges to academic subjects. The entire 
data set is available as [1.8MB XML file](https://www.lib.umich.edu/browse/categories/xml.php)
for download.

In the HLB, the call number for _Endorphins : new waves in brain chemistry_ maps
to the following categories:

* Science | Physiology
* Health Sciences | Physiology
* Health Sciences | Public Health (General)
* Science | Chemical Engineering
* Engineering | Chemical Engineering
* Health Sciences | Biological Chemistry
* Science | Chemistry | Biological Chemistry

This opens up potentially more accurate categorization of works for, say, 
faceting in a library catalog.

This gem gives a relatively time-efficient way to get the set of disciplines associated
with the given callnumber or callnumbers as part of indexing MARC records into Solr. 
This mapping is used in many places in the University Library at the University of 
Michigan, including the 
[Mirlyn Catalog](https://mirlyn.lib.umich.edu/)
(exposed as "Academic Discipline" in the facets) and ejournals/databases (and even 
Librarians!) via the [Browse page](https://www.lib.umich.edu/browse). 
 
This categorization may be useful for clustering/faceting
in similar applications at other institutions. Note that the actual creation and 
maintenance of the call number ranges is done by subject specialist librarians and 
is out of scope for this gem.

## Command line utilities: `fetch_new_hlb` and `hlb`

There are also a couple command line applications for managing and querying the
data.

* **fetch_new_hlb** tries to grab a new copy of the data from the umich website
  and serialize it to a ~500k file called `hlb.json.gz` in the given directory. 
  Useful for putting in a cron job to periodically update with fresh data
  
```bash

$> fetch_new_hlb

fetch_new_hlb -- get a new copy of the HLB ready for use by high_level_browse
and stick it in the given directory

   Usage: fetch_new_hlb <dir>
```

* **hlb** takes one or more callnumbers and returns a text display of the categories
  associated with them. It will stash a copy of the database in `Dir.tmpdir`if there 
  isn't one there already, and use it on subsequent calls so things aren't so 
  desperately slow. (To find your tmpdir, in your shell
  run `ruby -e 'require "tmpdir"; puts Dir.tmpdir'`)


```bash
$> hlb

hlb -- get high level browse data for an LC call number

Example:
   hlb "qa 11.33 .C4 .H3"
    or do several at once
   hlb "PN 33.4" "AC 1122.3 .C22" ...
 
# Let's try it
$> hlb "qa 11.33 .C4"
   
   Science | Mathematics
   Social Sciences | Education   
   
```


## A warning about (lack of) coverage

Note that not every possible valid callnumber will be necessarily be contained in any 
dicipline at all. Many books aren't academic in nature, and even then
coverage is known to have some holes. Some of the ranges cover essentially a 
single book in the umich collection. And, of course, not every record is going 
to have a LC Call Number, so there's that.

This is all to say: this may or may not be useful at your insitution. You'll 
have to experiment.

To help with this, there's a little script in the `bin/` directory called 
`test_marc_file_for_hlb` which will, when given a MARC-XML file (ending in `.xml`)
or a MARC-binary file (ending in anything else), output some statistics on
what kind of coverage you would get. It might be useful to send a test file 
through there to see what comes up. It looks in the `050` and the `852[h]` to
see if anything pops, but you can make it looks elsewhere pretty easily.

It produces something like this:

```
050 fields
     9790 total
      209 not recognized as LC call numbers
     9337 with at least one HLB category
      244 with NO category

Of 17642 records,
  9677 (54.85%) had a field that often contains an LC Call Number
  9262 (95.71%) of *those* had at least one HLB category

```

## Performance

On my laptop under normal load (e.g., not very scientific at all)
I get the following running in a single thread

```
  ruby 2.3  this gem       ~8500 lookups/second
  ruby 2.4  this gem       ~9100 lookups/second
  jruby 9   this gem     ~20,000 lookups/second
  jruby 9,  old HLB.jar    ~6500 lookups/second
  jruby 1.7 this gem             error, can't do named arguments since it's 1.9 mode
  jruby 1.7 old HLB.jar    ~6700 lookups/second
```

The [old HLB.jar](https://github.com/billdueber/HLB-Java) refers to a pure java version that I call from within
Jruby as part of my catalog indexing process now. Ithas a different (worse) algorithm, but is of
interest because it's what I'm writing this to replace.

## Installation

```bash
    gem 'high_level_browse'
```


## Contributing

1. Fork it ( https://github.com/[my-github-username]/high_level_browse/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
