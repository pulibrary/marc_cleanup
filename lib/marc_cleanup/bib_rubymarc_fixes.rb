module Marc_Cleanup

  def empty_876_3h_fix_rubymarc(record)
    record.fields.each do |field|
      field_index = record.fields.index(field)
      if field.tag == '876'
        subfields_to_delete = []
        curr_subfield = 0
        field.subfields.each do |subfield|
          if subfield.code =~ /[3h]/
            if subfield.value == ''
              subfields_to_delete.unshift(curr_subfield)
            end
          end
          curr_subfield += 1
        end
        subfields_to_delete.each do |i|
          record.fields[field_index].subfields.delete_at(i)
        end
      end
    end
    record
  end 

  def leaderfix_rubymarc(record)
    leader = record.leader
    unless leader =~ /[0-9]{5}[acdnp][acdefgijkmoprt][abcdims][\sa][\sa]22[0-9]{5}[12345678uzIJKLM\s][aciu\s][abcr\s]4500/
      length = leader[0, 5]
      if leader.match(/(^.{5})([acdnp])/) == nil
        status = 'n'
      else
        status = leader[5]
      end
      record_type = leader[6]
      bib_level = leader[7]
      if leader.match(/(^.{8})([a ])/) == nil
        control = ' '
      else
        control = leader[8]
      end
      character_scheme = leader[9]
      indsub = '22'
      base_addr = leader[12, 5]
      if leader.match(/(^.{17})([1-8uzIJKLM ])/) == nil
        enc_level = 'u'
      else
        enc_level = leader[17]
      end
      if leader.match(/(^.{18})([aciu ])/) == nil
        cat_form = 'u'
      else
        cat_form = leader[18]
      end
      if leader.match(/(^.{19})([abcr ])/) == nil
        multipart = ' '
      else
        multipart = leader[19]
      end
      final4 = '4500'
      fixed_leader = [length, status, record_type, bib_level, control, character_scheme, indsub, base_addr, enc_level, cat_form, multipart, final4].join
      record.leader = fixed_leader
    end
    record
  end

  def extra_space_fix_rubymarc(record)
    record.fields.each do |field|
      field_index = record.fields.index(field)
      if field.class == MARC::DataField && field.tag != '010'
        curr_subfield = 0
        if field.tag =~ /[1-469]..|0[2-9].|01[1-9]|7[0-5].|5[0-24-9].|53[0-24-9]/
          field.subfields.each do |subfield|
            record.fields[field_index].subfields[curr_subfield].value = subfield.value.gsub(/([[:blank:]]){2,}/, '\1').gsub(/^(.*)[[:blank:]]+$/, '\1').gsub(/^[[:blank:]]+(.*)$/, '\1')
            curr_subfield += 1
          end
        elsif field.tag == '533'
          field.subfields.each do |subfield|
            if subfield.code =~ /[^7]/
              record.fields[field_index].subfields[curr_subfield].value = subfield.value.gsub(/([[:blank:]]){2,}/, '\1').gsub(/^(.*)[[:blank:]]+$/, '\1').gsub(/^[[:blank:]]+(.*)$/, '\1')
            end
            curr_subfield += 1
          end
        elsif field.tag =~ /7[6-8]./
          field.subfields.each do |subfield|
            if subfield.code =~ /[a-v3-8]/
              record.fields[field_index].subfields[curr_subfield].value = subfield.value.gsub(/([[:blank:]]){2,}/, '\1').gsub(/^(.*)[[:blank:]]+$/, '\1').gsub(/^[[:blank:]]+(.*)$/, '\1')
            else
              record.fields[field_index].subfields[curr_subfield].value = subfield.value
            end
            curr_subfield += 1
          end
        elsif field.tag =~ /8../
          field.subfields.each do |subfield|
            if subfield.code =~ /[^w7]/
              record.fields[field_index].subfields[curr_subfield].value = subfield.value.gsub(/([[:blank:]]){2,}/, '\1').gsub(/^(.*)[[:blank:]]+$/, '\1').gsub(/^[[:blank:]]+(.*)$/, '\1')
            else
              record.fields[field_index].subfields[curr_subfield].value = subfield.value
            end
            curr_subfield += 1
          end
        end
      end
    end
    record
  end

  def invalid_xml_fix_rubymarc(record)
    record.leader.gsub!(/[\u0000-\u0008\u000B\u000C\u000E-\u001C\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF]/, ' ')
    curr_field = 0
    record.fields.each do |field|
      field_index = record.fields.index(field)
      if field.class == MARC::DataField
        curr_subfield = 0
        field.subfields.each do |subfield|            
          record.fields[field_index].subfields[curr_subfield].value.gsub!(/[\u0000-\u0008\u000B\u000C\u000E-\u001C\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF]/, ' ')
          curr_subfield += 1
        end
      else
        record.fields[field_index].value.gsub!(/[\u0000-\u0008\u000B\u000C\u000E-\u001C\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF]/, ' ')
      end
      curr_field += 1
    end
    record
  end

  def composed_chars_normalize_fix_rubymarc(record)
    curr_field = 0
    record.fields.each do |field|
      field_index = record.fields.index(field)
      if field.class == MARC::DataField
        curr_subfield = 0
        field.subfields.each do |subfield|
          fixed_subfield = ''
          prevalue = subfield.value
          if prevalue.match(/^.*[\u0653\u0654\u0655].*$/)
            prevalue = prevalue.unicode_normalize(:nfc)
          end
          prevalue.each_codepoint do |c|
            if c < 1570 || (7680..10792).include?(c)
              fixed_subfield << c.chr(Encoding::UTF_8).unicode_normalize(:nfd)
            else
              fixed_subfield << c.chr(Encoding::UTF_8)
            end
          end
          record.fields[field_index].subfields[curr_subfield].value = fixed_subfield
          curr_subfield += 1
        end
      end
      curr_field += 1
    end
    record
  end

  def composed_chars_fix_rubymarc(record)
    record.fields.each do |field|
      field_index = record.fields.index(field)
      if field.class == MARC::DataField
        curr_subfield = 0
        field.subfields.each do |subfield|
          fixed_subfield = ''
          subfield.value.each_codepoint do |c|
            if c < 12364 || c > 64217
              fixed_subfield << c.chr(Encoding::UTF_8).unicode_normalize(:nfd)
            else
              fixed_subfield << c.chr(Encoding::UTF_8)
            end
          end
          record.fields[field_index].subfields[curr_subfield].value = fixed_subfield
          curr_subfield += 1
        end
      end
    end
    record
  end

  def field_delete_rubymarc(tag, record)
    curr_field = 0
    fields_to_delete = []
    record.fields.each do |field|
      if field.tag == tag
        fields_to_delete.unshift(curr_field)
      end
      curr_field += 1
    end
    unless fields_to_delete.empty?
      fields_to_delete.each do |i|
        record.fields.delete_at(i)
      end
    end
    record
  end

  def tab_newline_fix_rubymarc(record)
    record.leader.gsub!(/\x09/, ' ')
    record.fields.each do |field|
      field_index = record.fields.index(field)
      if field.class == MARC::DataField
        curr_subfield = 0
        field.subfields.each do |subfield|            
          record.fields[field_index].subfields[curr_subfield].value.gsub!(/[\x09\n\r]/, ' ')
          curr_subfield += 1
        end
      else
        record.fields[field_index].value.gsub!(/[\x09\n\r]/, ' ')
      end
    end
    record
  end

  def empty_subfield_fix_rubymarc(record)
    fields_to_delete = []
    curr_field = 0
    record.fields.each do |field|
      if field.class == MARC::DataField
        curr_subfield = 0
        subfields_to_delete = []
        field.subfields.each do |subfield|
          if subfield.value == ''
            subfields_to_delete.unshift(curr_subfield)
          end
          curr_subfield += 1
        end
        subfields_to_delete.each do |i|
          record.fields[curr_field].subfields.delete_at(i)
        end
        if record.fields[curr_field].subfields.empty?
          fields_to_delete.unshift(curr_field)
        end
        curr_field += 1
      else
        curr_field += 1
      end
    end
    unless fields_to_delete.empty?
      fields_to_delete.each do |i|
        record.fields.delete_at(i)
      end
    end
    record
  end

end
