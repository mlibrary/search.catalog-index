module MARC
  class MARC4J

    # Given a marc4j record, return a rubymarc record
    # check for valid subfield code
    def marc4j_to_rubymarc(marc4j)
      rmarc = MARC::Record.new
      rmarc.leader = marc4j.getLeader.marshal

      marc4j.getControlFields.each do |marc4j_control|
        rmarc.append( MARC::ControlField.new(marc4j_control.getTag(), marc4j_control.getData )  )
      end

      marc4j.getDataFields.each do |marc4j_data|
        i1 = marc4j_data.getIndicator1.chr(Encoding::UTF_8)
        i2 = marc4j_data.getIndicator2.chr(Encoding::UTF_8)
        if i1 !~ /[ \dA-Za-z!"#$%&'()*+,-.\/:;<=>?{}_^`~\[\]\\]/ or i2 !~ /[ \dA-Za-z!"#$%&'()*+,-.\/:;<=>?{}_^`~\[\]\\]/
          if @logger
            @logger.warn("Marc4JReader: Invalid MARC data, record id #{marc4j.getControlNumber}, field #{marc4j_data.tag}, invalid indicator(s) '#{i1}' '#{i2}'. Skipping field, but continuing with record.")
          end
          next
        end
        rdata = MARC::DataField.new(  marc4j_data.getTag,  marc4j_data.getIndicator1.chr, marc4j_data.getIndicator2.chr )

        marc4j_data.getSubfields.each do |subfield|

          sf_code = subfield.getCode.chr(Encoding::UTF_8)
          # We assume Marc21, skip corrupted data
          # if subfield.getCode is more than 255, subsequent .chr
          # would raise.

          #if sf_code !~ /[a-z0-9]/
          if sf_code !~ /[\dA-Za-z!"#$%&'()*+,-.\/:;<=>?{}_^`~\[\]\\]/
            if @logger
              @logger.warn("Marc4JReader: Invalid MARC data, record id #{marc4j.getControlNumber}, field #{marc4j_data.tag}, invalid subfield code '#{sf_code}'. Skipping subfield, but continuing with record.")
            end
            next
          end

          rsubfield = MARC::Subfield.new(subfield.getCode.chr, subfield.getData)
          rdata.append rsubfield
        end

        rmarc.append rdata
      end

      return rmarc
    end
  end
end
