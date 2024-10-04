# Zinzout

`Zinzout` is a naïve wrapper that uses Zlib::Gzip[Reader/Writer] to make
dealing with gzipped files a little easier.

_Basically_:
* When given a filename (and optionaly encoding), will attempt to open
the appropriate file and correctly deal with gzippedness transparently
* When given no filename, will simply return either STDIN or STDOUT

## Examples

```ruby

# The following code should work no matter which filename is used

# filename = nil # STDIN/STDOUT
# filename = 'textfile.txt'
filename = 'textfile.txt.gz'

outfilename = 'results_' + filename unless filename.nil?

infile = Zinzout.zin(filename, encoding: "utf-8")
outfile = Zinzout.zout(outfilename) # "utf-8" is the default

infile.each {|line| blah.blah }
outfile.puts "All done!"

# Much like using `File#open`, Zinzout will automatically close files
# (but not STDIN/STDOUT!) if given a block

Zinzout.zout(outfilename) do |outfile|
  Zinzout.zin(filename) do |infile|
    infile.each do |line|
      outfile.puts(line)
    end
  end
end

```

## Determining gzippedness

`Zinzout` isn't smart. It's just convenient.

* `Zinzout::zin`
  * _No filename / filename.nil?_: STDIN
  * _Filename (String or Pathname)_:
    * Sniff the file to see if it's gzipped
    * Return either a `Zlib::GzipReader` or a `File`
* `Zinzout::zout`
  * _No filename / filename.nil?_: STDOUT
  * _Filename (String or Pathname) ends in .gz_: `Zlib::GzipWriter`
  * _Filename does not end in .gz_: `File`
  
In particular, note that there's no attempt to sniff STDIN to see if
it's gzipped, or to force compression before writing to STDOUT.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/billdueber/zinzout.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
