module MarcCleanup
  def no_001?(record)
    record['001'].nil? ? true : false
  end

  def leader_errors?(record)
    correct_leader = /[0-9]{5}[acdnp][ac-gijkmoprt][a-dims][\sa][\sa]22[0-9]{5}[1-8uzI-M\s][aciu\s][abcr\s]4500/
    record.leader =~ correct_leader ? false : true
  end

  def invalid_tag?(record)
    record.tags.find { |x| x =~ /[^0-9]/ } ? true : false
  end

  def invalid_indicators?(record)
    record.fields.each do |field|
      next unless field.class == MARC::DataField
      return true unless field.indicator1 =~ /^[0-9 ]$/ && field.indicator2 =~ /^[0-9 ]$/
    end
    false
  end

  def invalid_subfield_code?(record)
    record.fields.each do |field|
      next unless field.class == MARC::DataField
      field.subfields.each do |subfield|
        return true unless subfield.code =~ /^[0-9a-z]$/
      end
    end
    false
  end

  def empty_subfields?(record)
    record.fields.each do |field|
      next unless field.class == MARC::DataField
      field.subfields.each do |subfield|
        return true if subfield.value =~ /^[[:blank:]]*$/
      end
    end
    false
  end

  def extra_spaces?(record)
    blank_regex = /^.*[[:blank:]]{2,}.*$|^.*[[:blank:]]+$|^[[:blank:]]+(.*)$/
    record.fields.each do |field|
      next unless field.class == MARC::DataField && field.tag != '010'
      if field.tag =~ /[1-469]..|0[2-9].|01[1-9]|7[0-5].|5[0-24-9].|53[0-24-9]/
        field.subfields.each do |subfield|
          return true if subfield.value =~ blank_regex
        end
      elsif field.tag == '533'
        field.subfields.each do |subfield|
          next if subfield.code == '7'
          return true if subfield.value =~ blank_regex
        end
      elsif field.tag =~ /7[6-8]./
        field.subfields.each do |subfield|
          next unless subfield.code =~ /[a-v3-8]/
          return true if subfield.value =~ blank_regex
        end
      elsif field.tag =~ /8../
        field.subfields.each do |subfield|
          next unless subfield.code =~ /[^w7]/
          return true if subfield.value =~ blank_regex
        end
      end
    end
    false
  end

  def multiple_no_245?(record)
    field_count = 0
    record.fields.each do |field|
      next unless field.tag == '245'
      field_count += 1
    end
    field_count != 1 ? true : false
  end

  def pair_880_errors?(record)
    pair_880s = []
    linked_fields = []
    return false unless record['880']
    record.fields.each do |field|
      return true if field.tag == '880' && field['6'].nil?
      next unless field.tag =~ /^[0-8]..$/ && field.class == MARC::DataField && field['6']
      if field.tag == '880'
        pair_880s << field['6'].gsub(/^([0-9]{3}-[0-9]{2}).*$/, '\1')
      else
        linked_fields << "#{field.tag}-#{field['6'].gsub(/^880-([0-9]{2}).*$/, '\1').chomp}"
      end
    end
    pair_880s.delete_if { |x| x =~ /^.*-00/ }
    return true if pair_880s.uniq != pair_880s || pair_880s.uniq.sort != linked_fields.uniq.sort
    false
  end

  def has_130_240?(record)
    return true if (%w[130 240] - record.tags).empty?
    false
  end

  def multiple_1xx?(record)
    main_entry_count = 0
    record.fields.each do |field|
      next unless field.tag =~ /^1..$/
      main_entry_count += 1
    end
    return true unless main_entry_count < 2
    false
  end

  def bad_utf8?(record)
    record.to_s.scrub != record.to_s ? true : false
  end

  def bad_utf8_identify(record)
    record.fields.each do |field|
      field_index = record.fields.index(field)
      if field.class == MARC::DataField
        field.subfields.each do |subfield|
          subfield_index = record.fields[field_index].subfields.index(subfield)
          record.fields[field_index].subfields[subfield_index].value.scrub! { |bytes| '░' + bytes.unpack('H*')[0] + '░' }.force_encoding('UTF-8')
        end
      else
        record.fields[field_index].value.scrub! { |bytes| '░' + bytes.unpack('H*')[0] + '░' }.force_encoding('UTF-8')
      end
    end
    record
  end

  def tab_newline_char?(record)
    pattern = /[\x09\n\r]/
    record.fields.each do |field|
      if field.class == MARC::DataField
        field.subfields.each do |subfield|
          return true if subfield.value =~ pattern
        end
      elsif field.value =~ pattern
        return true
      end
    end
    false
  end

  def invalid_xml_identify(record)
    pattern = /[\u0000-\u0008\u000B\u000C\u000E-\u001C\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF]/
    0.upto(record.fields.size - 1) do |field_num|
      next unless record.fields[field_num].to_s =~ pattern
      if record.fields[field_num].class == MARC::DataField
        0.upto(record.fields[field_num].subfields.size - 1) do |subf_num|
          next if record.fields[field_num].subfields[subf_num].value.nil?
          record.fields[field_num].subfields[subf_num].value.gsub!(pattern, '░\1░')
        end
      else
        record.fields[field_num].value.gsub!(pattern, '░\1░') unless record.fields[field_num].value.nil?
      end
    end
    record
  end

  def invalid_xml_chars?(record)
    pattern = /[\u0000-\u0008\u000B\u000C\u000E-\u001C\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF]/
    record.to_s =~ pattern ? true : false
  end

  def combining_chars_identify(record)
    pattern = /[^\p{L}\p{M}]\p{M}+/
    0.upto(record.fields.size - 1) do |field_num|
      if record.fields[field_num].class == MARC::DataField
        0.upto(record.fields[field_num].subfields.size - 1) do |subf_num|
          record.fields[field_num].subfields[subf_num].value.gsub!(pattern, '░\1░')
        end
      else
        record.fields[field_num].value.gsub!(pattern, '░\1░')
      end
    end
    record
  end

  def combining_char_errors?(record)
    pattern = /[^\p{L}\p{M}]\p{M}+/
    record.to_s =~ pattern ? true : false
  end

  def invalid_chars?(record)
    good_chars = CHARSET
    record.fields.each do |field|
      if field.class == MARC::DataField
        field.subfields.each do |subfield|
          next if subfield.value.nil?
          subfield.value.each_char do |c|
            return true unless good_chars.include?(c.ord)
          end
        end
      else
        field.value.each_char do |c|
          return true unless good_chars.include?(c.ord)
        end
      end
    end
    false
  end

  def invalid_chars_identify(record)
    good_chars = CHARSET
    0.upto(record.fields.size - 1) do |field_num|
      if record.fields[field_num].class == MARC::DataField
        0.upto(record.fields[field_num].subfields.size - 1) do |subf_num|
          next if record.fields[field_num].subfields[subf_num].value.nil?
          temp_value = ''
          record.fields[field_num].subfields[subf_num].value.each_char do |c|
            temp_value << good_chars.include?(c.ord) ? c : "░#{c}░"
          end
          record.fields[field_num].subfields[subf_num].value = temp_value
        end
      elsif record.fields[field_num].value
        temp_value = ''
        field.value.each_char do |c|
          temp_value << good_chars.include?(c.ord) ? c : "░#{c}░"
        end
        record.fields[curr_field].value = temp_value
      end
    end
    record
  end

  def composed_chars_errors?(record)
    record.fields.each do |field|
      if field.class == MARC::DataField
        field.subfields.each do |subfield|
          subfield.value.each_codepoint do |c|
            next unless c < 1570 || (7680..10_792).cover?(c)
            return true unless c.chr(Encoding::UTF_8).unicode_normalized?(:nfd)
          end
          if subfield.value =~ /^.*[\u0653\u0654\u0655].*$/
            return true unless subfield.value.unicode_normalized?(:nfc)
          end
        end
      else
        field.value.each_codepoint do |c|
          next unless c < 1570 || (7680..10_792).cover?(c)
          return true unless c.chr(Encoding::UTF_8).unicode_normalized?(:nfd)
        end
        if field.value =~ /^.*[\u0653\u0654\u0655].*$/
          return true unless field.value.unicode_normalized?(:nfc)
        end
      end
    end
    false
  end

  def relator_chars?(record)
    record.fields.each do |field|
      if field.tag =~ /[17][01]0/
        field.subfields.each do |subfield|
          next unless subfield.code == 'e' && subfield.value =~ /.*[^a-z, \.].*/
          return true
        end
      elsif field.tag =~ /[17]11/
        field.subfields.each do |subfield|
          next unless subfield.code == 'j' && subfield.value =~ /.*[^a-z, \.].*/
          return true
        end
      end
    end
    false
  end

  def x00_subfq?(record)
    record.fields.each do |field|
      next unless field.tag =~ /[167]00/
      field.subfields.each do |subfield|
        next unless subfield.code == 'q' && subfield.value =~ /^(?!\([^\)]*\))$/
        return true
      end
    end
    false
  end

  def no_comma_x00?(record)
    record.fields.each do |field|
      next unless field.tag =~ /[167]00/
      code_array = ''
      field.subfields.each do |subfield|
        code_array << subfield.code
      end
      subfx_d_index = code_array.index(/.d/)
      return true if subfx_d_index && field.subfields[subfx_d_index].value =~ /^.*[^,]$/
    end
    false
  end

  def relator_comma?(record)
    comma_regex = /^.*[^,]$/
    record.fields.each do |field|
      next unless field.tag =~ /[17][01][01]/
      code_array = ''
      field.subfields.each do |subfield|
        code_array << subfield.code
      end
      if field.tag =~ /[17][01]0/
        subfx_e_index = code_array.index(/.e/)
        return true if subfx_e_index && field.subfields[subfx_e_index].value =~ comma_regex
      elsif field.tag =~ /[17]11/
        subfx_j_index = code_array.index(/.j/)
        return true if subfx_j_index && field.subfields[subfx_j_index].value =~ comma_regex
      end
    end
    false
  end

  def heading_end_punct?(record)
    punct_regex = /.*[^"\).\!\?\-]$/
    record.fields.each do |field|
      next unless field.tag =~ /^[167][0-5].$/ && field.indicator2 =~ /[^47]/
      code_array = ''
      field.subfields.each do |subfield|
        code_array << subfield.code
      end
      last_heading_subfield_index = code_array.index(/[a-vx-z8][^a-vx-z8]*$/)
      return true if last_heading_subfield_index && field.subfields[last_heading_subfield_index].value =~ punct_regex
    end
    false
  end

  def lowercase_headings?(record)
    record.fields.each do |field|
      next unless field.tag =~ /[167]../
      return true if field['a'] =~ /^[a-z]{3,}/
    end
    false
  end
end
