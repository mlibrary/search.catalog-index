module HathiTrust
  module Traject # Just need to define it so eval order doesn't matter
  end
end

module HathiTrust::Traject::Macros

  # Need a way to skip some fields, notably 710s with a $9 == 'WaSeSS'
  # because we've got JSTOR showing up as an author
  #
  # Takes the same first and last arguments as extract_marc, but throws in a second argument
  # that is a lambda of the form
  #
  #  func(marc_record, field) => boolean
  #
  # All record/field combinations that return true from that func will be skipped.
  #
  def extract_marc_unless(spec, skipif, options = {})
    unless (options.keys - Traject::Macros::Marc21::EXTRACT_MARC_VALID_OPTIONS).empty?
      raise RuntimeError.new("Illegal/Unknown argument '#{(options.keys - EXTRACT_MARC_VALID_OPTIONS).join(', ')}' in extract_marc at #{Traject::Util.extract_caller_location(caller.first)}")
    end


    if translation_map_arg = options.delete(:translation_map)
      translation_map = Traject::TranslationMap.new(translation_map_arg)
    else
      translation_map = nil
    end

    extractor = Traject::MarcExtractor.new(spec, options).dup

    # Redefine the each_matching_line on this (and only this!) extractor
    # to skip fields that match the passed lambda
    #
    # This isn't deep, deep magic, but it's not exactly intuitive.
    # Basically, we're opening up the eigenclass for this one
    # instance and redefining the method that determines if
    # a field matches the spec
    #
    # Most of it is copied from the original implementation


    # First, give us a place to put the skip lambda
    def extractor.skipif=(skipif)
      @skipif = skipif
    end

    # And a eml that uses it
    def extractor.each_matching_line(marc_record)
      marc_record.fields(@interesting_tags_hash.keys).each do |field|

        # skip if lmdba.call(field) returns true
        next if @skipif[marc_record, field]

        # Make sure it matches indicators too, specs_covering_field
        # doesn't check that.
        specs_covering_field(field).each do |spec|
          if spec.matches_indicators?(field)
            yield(field, spec, self)
          end
        end

      end
    end

    # Set the skipif
    extractor.skipif = skipif

    # Now return a normal marc extractor-type lambda
    lambda do |record, accumulator, context, &blk|
      accumulator.concat extractor.extract(record)
      Traject::Macros::Marc21.apply_extraction_options(accumulator, options, translation_map)
      if blk
        blk.call(record, accumulator, context)
      end
    end


  end


  # Get a namespaced place to put all the ht stuff
  def self.setup
    lambda do |record, context|
      context.clipboard[:ht] = {}
    end
  end

  def macr4j_as_xml
    lambda do |r, acc, context|
      xmlos = java.io.ByteArrayOutputStream.new
      writer = org.marc4j.MarcXmlWriter.new(xmlos)
      writer.setUnicodeNormalization(true)
      writer.write(context.clipboard[:ht][:marc4j])
      writer.writeEndDocument();
      acc << xmlos.toString
    end
  end


  def get_date
    lambda do |r, acc, context|
      d = if defined? context.clipboard[:ht][:date]
            context.clipboard[:ht][:date]
          else
            HTMacros.get_date(r)
          end
      acc.replace [d] if d
    end
  end

  def get_raw_date
    lambda do |r, acc, context|
      d = if defined? context.clipboard[:ht][:rawdate]
            context.clipboard[:ht][:rawdate]
          else
            HTMacros.get_raw_date(r)
          end
      acc << d if d
    end
  end


  # Stick some dates into the context object for later use
  def extract_date_into_context

    lambda do |r, context|
      context.clipboard[:ht][:rawdate] = HTMacros.get_raw_date(r)
      context.clipboard[:ht][:date] = HTMacros.convert_raw_date(context.clipboard[:ht][:rawdate])
      context.clipboard[:ht][:display_date] = HTMacros.get_display_date(r)
    end
  end

  # get the title field for display, remove bracketed subfield h data, leaving any trailing punctuation
  def extract_display_title(spec='245abdefghknp', opts={})
    extractor = Traject::MarcExtractor.cached(spec, opts)

    lambda do |record, accumulator, context|
      extractor.collect_matching_lines(record) do |field, spec|
        str = extractor.collect_subfields(field, spec).first
        #str = HTMacros.remove_gmd(field, str.first)
        subh = nil     
        field.subfields.collect do |subfield|
          subh = subfield.value if subfield.code == 'h'
        end
        #return str unless subh
        if subh 
          subh.gsub!(/(\[.*?\]).*/, '\1') 
          str.gsub!(/#{Regexp.escape(subh)}/, '') 
        end
        accumulator << str if str
      end
    end
  end

  # id from 001 field--
  def record_id

    lambda do |r, accumulator, context|
      id = r['001'].value
      if (id =~ /\A\d{9}\Z/)
        id = '11' + id 
      end
   
      accumulator << id
    end
  end

  # determine the record source
  def record_source

    lambda do |r, accumulator, context|
      id = context.output_hash['id'].first
      if (id =~ /\A11\d{9}\Z/)
        record_source = 'zephir'
      elsif (id =~ /\A99.*?6381\Z/)
        record_source = 'alma'
      else
        record_source = 'unknown'
      end
   
      context.clipboard[:ht][:record_source] = record_source
      accumulator << record_source
    end
  end

  # get display string for ht links based on righs and ETAS status
  def statusFromRights(rights, etas = false)

    if rights =~ /^(pd|world|cc|und-world|ic-world)/
      status = "Full text";
    elsif etas
      status = "Full text available, simultaneous access is limited (HathiTrust log in required)"
    else
      status = "Search only (no full text)"
    end
  end

  class HTMacros

    # Some dates we're not going to bother with
    BAD_DATE_TYPES = {
        'n' => true,
        #'u' => true,
        'b' => true
    }

    CONTAINS_FOUR_DIGITS = /(\d{4})/
    DATE_RANGE = /(\d{4}-\d{4})/

    # Get a date from a record, as best you can
    # Try to get it from the 008; if not, the 260
    def self.get_raw_date(r)
      get_008_date(r) or get_260_date(r)
    end


    def self.get_display_date(r)
      get_display_date_008(r) or get_display_date_26x(r)
    end

    def self.get_date(r)
      raw = self.get_raw_date(r)
      self.convert_raw_date(raw)
    end

    def self.convert_raw_date(d)
      return nil unless d
      d.gsub(/u/, '0')
    end


    def self.bad_date_type?(ohoh8)
      BAD_DATE_TYPES.has_key? ohoh8[6]
    end

    def self.get_008_date(r)
      return nil unless r['008'] and r['008'].value.size > 10

      ohoh8 = r['008'].value

      return nil if bad_date_type?(ohoh8)

      date = ohoh8[7..10].downcase
      return nil if date == '0000' or date =~ /\|/
      return nil unless date =~ /\A\d[\du]{3}/
      return date
    end

    def self.get_display_date_008(r)
      return nil unless r['008'] and r['008'].value.size > 10

      ohoh8 = r['008'].value

      date_type = ohoh8[6].downcase
      date1 = ohoh8[7..10].downcase
      date2 = ohoh8[11..14].downcase
      return nil if date_type =~ /[beinprst|]/ 		# all of these types use a single date in date1
      return nil if date1 == '0000' or date1 =~ /\|/ or date2 == '0000' or date2 =~ /\|/ 	# nothing in date2
      #return nil if date1 == '9999' or date2 == '9999'
      return nil if date1 == '9999'
      if date_type == 'q'
        # Let's go with the "Possibly between 1880-1880" pattern
        if date1 =~ /\d{4}/ and date2 =~ /\d{4}/ and date1 < date2 
          return "Possibly between " + [date1, date2].join("-")
        end
      end

      if date1 =~ /\d{4}/ and date2 =~ /(9999|uuuu)/ 
        return date1.concat("-")
      end
      return nil unless date1 =~ /\d{4}/ and date2 =~ /\d{4}/
      return nil unless date1 < date2			# sanity check
      return [date1, date2].join("-")
    end

    def self.get_260_date(r)
      return nil unless r['260'] and r['260']['c']
      m = CONTAINS_FOUR_DIGITS.match(r['260']['c'])
      return m && m[1]
    end

    def self.get_display_date_26x(r)
      date_26x = get_26x_sub_c(r)
      date_range = DATE_RANGE.match(date_26x)
      return nil unless date_range
      return date_range
    end 
    
    def self.get_26x_sub_c(r)
      #r['260'] and return r['260']['c']
      $subc = Traject::MarcExtractor.cached("260c").extract(r).first
      $subc and return $subc
      $subc = Traject::MarcExtractor.cached("264|*1|c").extract(r).first
      $subc and return $subc
    end

    # Get a date range for easier faceting. 1800+ goes to the decade,
    # before that goes to the century, pre-1500 gets the string
    # "Pre-1500"
    #
    # Returns 'nil' for dates after 2100, presuming they're just wrong
    def self.compute_date_range(date)
      return nil if date.nil?

      date = date.to_s

      if date.to_i < 1500
        return "Pre-1500"
      end


      case date.to_i
      when 1500..1800 then
        century = date[0..1]
        return century + '00-' + century + '99'
      when 1801..2100 then
        decade = date[0..2]
        return decade + "0-" + decade + "9";
      end
      return nil # default

    end

    # Take in a field, a string extracted from that field, and a spec and
    # return the filing version (i.e., the string without the
    # non-filing characters)

    def self.remove_gmd(field, str)
#      # Control fields don't have non-filing characters
#      return str if field.kind_of? MARC::ControlField
  
#      # 2nd indicator must be > 0
#      ind2 = field.indicator2.to_i
#      return str unless ind2 > 0

      # The spechash must either (a) have no subfields specified, or
      # (b) include the first subfield in the record

      subh = nil     
      field.subfields.collect do |subfield|
        subh = subfield.value if subfield.code == 'h'
      end
      return str unless subh
      subh.gsub!(/(\[.*?\]).*/, '\1') 
      return str.gsub(/#{Regexp.escape(subh)}/, '') 
    end

  end

end
