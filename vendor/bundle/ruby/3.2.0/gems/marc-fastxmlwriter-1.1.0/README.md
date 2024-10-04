# Marc::FastXMLWriter

[![Build Status](https://travis-ci.org/billdueber/marc-fastxmlwriter.svg?branch=master)](https://travis-ci.org/billdueber/marc-fastxmlwriter)

Turn a single ruby-marc Record object into a MARC-XML string, but faster.


```ruby

require 'marc/fastxmlwriter'

r = MARC::Reader.new('mystuff.mrc').first
xmlstring = MARC::FastXMLWriter.single_record_document(r)
xml_with_namespace = MARC::FastXMLWriter.single_record_document(r, :include_namespace=>true)
```




## Installation

Add this line to your application's Gemfile:

```ruby
gem 'marc-fastxmlwriter'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install marc-fastxmlwriter


## Contributing

1. Fork it ( https://github.com/[my-github-username]/marc-fastxmlwriter/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
