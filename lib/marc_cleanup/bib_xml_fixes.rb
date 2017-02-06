module Marc_Cleanup

  def xml_leader_fix(record)
    fixed_record = ''
    fixed_record << "<record xmlns='http:\/\/www.loc.gov\/MARC21\/slim'>"
    record_leader = record.match(/<leader>[^<]+<\/leader>/)[0]
    leader_contents = record_leader.gsub(/<leader>([^<]+)<\/leader>/, '\1')
    record_fields = record.scan(/(<datafield[^>]*>(?:<subfield code='.'>[^<]*<\/subfield>)*<\/datafield>)|(<controlfield[^>]*>[^<]*<\/controlfield>)/).flatten.delete_if {|value| value == nil}
    unless leader_contents.match(/[0-9]{5}[acdnp][acdefgijkmoprt][abcdims][\sa][\sa]22[0-9]{5}[12345678uzIJKLM\s][aciu\s][abcr\s]4500/)
      length = leader_contents[0, 5]
      if leader_contents.match(/(^.{5})([acdnp])/) == nil
        status = 'n'
      else
        status = leader_contents[5]
      end
      record_type = leader_contents[6]
      bib_level = leader_contents[7]
      if leader_contents.match(/(^.{8})([a ])/) == nil
        control = ' '
      else
        control = leader_contents[8]
      end
      character_scheme = leader_contents[9]
      indsub = '22'
      base_addr = leader_contents[12, 5]
      if leader_contents.match(/(^.{17})([1-8uzIJKLM ])/) == nil
        enc_level = 'u'
      else
        enc_level = leader_contents[17]
      end
      if leader_contents.match(/(^.{18})([aciu ])/) == nil
        cat_form = 'u'
      else
        cat_form = leader_contents[18]
      end
      if leader_contents.match(/(^.{19})([abcr ])/) == nil
        multipart = ' '
      else
        multipart = leader_contents[19]
      end
      final4 = '4500'
      fixed_leader = [length, status, record_type, bib_level, control, character_scheme, indsub, base_addr, enc_level, cat_form, multipart, final4].join
      record_leader = "<leader>#{fixed_leader}<\/leader>"
    end
    fixed_record << record_leader
    record_fields.each do |field|
      fixed_record << field
    end
    fixed_record << "<\/record>"
    fixed_record
  end
        
  def xml_space_fix(record)
    fixed_record = ''
    fixed_record << "<record xmlns='http:\/\/www.loc.gov\/MARC21\/slim'>"
    record_leader = record.match(/<leader>[^<]+<\/leader>/)[0]
    record_fields = record.scan(/(<datafield[^>]*>(?:<subfield code='.'>[^<]*<\/subfield>)*<\/datafield>)|(<controlfield[^>]*>[^<]*<\/controlfield>)/).flatten.delete_if {|value| value == nil}
    fixed_record << record_leader
    record_fields.each do |field|
      if field.match(/^<controlfield/)
        fixed_record << field
      else
        field_tag = field.match(/(?:<datafield.*tag=\')([^']{3})(?:.*)/)[1]
        if field_tag =~ /[1-469]..|0[2-9].|01[1-9]|7[0-5].|5[0-24-9].|53[0-24-9]/
          field.gsub!(/([[:blank:]]){2,}/, '\1')
          fixed_record << field
        elsif field_tag == '533'
          fixed_field = ''
          fixed_field << field.gsub(/^(<datafield[^>]*>).*$/, '\1')
          subfields = field.scan(/<subfield code='.'>[^<]*<\/subfield>/)
          subfields.each do |subfield|
            if subfield.match(/<subfield code=\'[^7]\'/)
              fixed_field << subfield.gsub(/([[:blank:]]){2,}/, '\1')
            else
              fixed_field << subfield
            end
          end
          fixed_record << fixed_field
        elsif field_tag =~ /7[6-8]./
          fixed_field = ''
          fixed_field << field.gsub(/^(<datafield[^>]*>).*$/, '\1')
          subfields = field.scan(/<subfield code='.'>[^<]*<\/subfield>/)
          subfields.each do |subfield|
            if subfield.match(/<subfield code=\'[a-v3-8]\'/)
              fixed_field << subfield.gsub(/([[:blank:]]){2,}/, '\1')
            else
              fixed_field << subfield
            end
          end
          fixed_record << fixed_field
        elsif field_tag =~ /8../
          fixed_field = ''
          fixed_field << field.gsub(/^(<datafield[^>]*>).*$/, '\1')
          subfields = field.scan(/<subfield code='.'>[^<]*<\/subfield>/)
          subfields.each do |subfield|
            if subfield.match(/<subfield code=\'[^w7]\'/)
              fixed_field << subfield.gsub(/([[:blank:]]){2,}/, '\1')
            else
              fixed_field << subfield
            end
          end
          fixed_record << fixed_field
        else
          fixed_record << field
        end
      end
    end
  fixed_record << "<\/record>"
  fixed_record
  end
end
