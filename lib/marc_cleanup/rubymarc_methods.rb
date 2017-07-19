module Marc_Cleanup

  def leader_errors_rubymarc(record)
    unless record.leader =~ /[0-9]{5}[acdnp][acdefgijkmoprt][abcdims][\sa][\sa]22[0-9]{5}[12345678uzIJKLM\s][aciu\s][abcr\s]4500/
      record
    end
  end

  def invalid_indicators_rubymarc(record)
    bad_record = false
    record.fields.each do |field|
      if field.class == MARC::DataField
        if field.indicator1 =~ /^[^0-9 ]$/ || field.indicator2 =~ /^[^0-9 ]$/
          bad_record = true
        end
      end
    end
    if bad_record
      record
    else
      bad_record
    end
  end

  def multiple_245_rubymarc(record)
    field_count = 0
    record.fields.each do |field|
      if field.tag == '245'
        field_count += 1
      end
    end
    if field_count > 1
      record
    else
      bad_record = false
    end
  end

  def paired_880_error_rubymarc(record)
    bad_record = false 
    pair_880s = []
    if record['880']
      has_880 = true
      record.fields.each do |field|
        if field.tag == '880'
          pair_880s << field['6']
        end
      end
    end
    if pair_880s.include?(nil)
      bad_record = true
    end
    pair_880s.delete_if{|x| x.nil? || x =~ /^.*-00/}
    if has_880 && pair_880s.uniq != pair_880s
      bad_record = true
    end
    if bad_record
      record
    else
      bad_record
    end
  end

  def has_130_240_rubymarc(record)
    if record.tags.include?("130") && record.tags.include?("240")
      record
    else
      bad_record = false
    end
  end

  def multiple_1xx_rubymarc(record)
    main_entry_count = 0
    record.fields.each do |field|
      if field.tag =~ /^1..$/
        main_entry_count += 1
      end
    end
    if main_entry_count > 1
      record
    else
      bad_record = false
    end
  end

  def invalid_tag_rubymarc(record)
    if record.tags.count{|x|x.match(/[^0-9]/)} > 0
      record
    else
      bad_record = false
    end
  end  

  def invalid_subfield_code_rubymarc(record)
    bad_record = false
    record.fields.each do |field|
      if field.class == MARC::DataField
        field.subfields.each do |subfield|
          if subfield.code =~ /^[^0-9a-z]$/
            bad_record = true
          end
        end
      end
    end
    if bad_record
      record
    else
      bad_record
    end
  end

  def tab_newline_char_rubymarc(record)
    bad_record = false
    record.fields.each do |field|
      if field.class == MARC::DataField
        field.subfields.each do |subfield|
          if subfield.value.match(/[\x09\n\r]/)
            bad_record = true
          end
        end
      else
        if field.value.match(/[\x09\n\r]/)
          bad_record = true
        end
      end
    end
    if bad_record
      record
    else
      bad_record
    end
  end

  def invalid_xml_chars_rubymarc(record)
    bad_record = false
    curr_field = 0
    record.fields.each do |field|
      if field.class == MARC::DataField
        curr_subfield = 0
        field.subfields.each do |subfield|
          if subfield.value =~ /^.*[\u0000-\u0008\u000B\u000C\u000E-\u001C\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF].*$/
            bad_record = true
            record.fields[curr_field].subfields[curr_subfield].value = subfield.value.scrub!{|bytes| '░'+bytes.unpack('H*')[0]+'░' }.force_encoding("UTF-8")
          end
          curr_subfield += 1
        end
      else
        if field.value =~ /^.*[\u0000-\u0008\u000B\u000C\u000E-\u001C\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF].*$/
          bad_record = true
          record.fields[curr_field].value = field.value.scrub!{|bytes| '░'+bytes.unpack('H*')[0]+'░' }.force_encoding("UTF-8")
        end
      end
      curr_field += 1
    end
    if bad_record
      record
    else
      bad_record
    end
  end

  def combining_chars_rubymarc(record)
    bad_record = false
    curr_field = 0
    record.fields.each do |field|
      if field.class == MARC::DataField
        curr_subfield = 0
        field.subfields.each do |subfield|
          if subfield.value =~ /^.*[^\p{L}\p{M}]\p{M}+.*$/
            bad_record = true
            record.fields[curr_field].subfields[curr_subfield].value = subfield.value.gsub(/([^\p{L}\p{M}]\p{M}+)/, '░\1░')
          end
          curr_subfield += 1
        end
      else
        if field.value =~ /^.*[^\p{L}\p{M}]\p{M}+.*$/
          bad_record = true
          record.fields[curr_field].value = field.value.gsub(/([^\p{L}\p{M}]\p{M}+)/, '░\1░')
        end
      end
      curr_field += 1
    end
    if bad_record
      record
    else
      bad_record
    end
  end

  def no_001_rubymarc(record)
    if record['001'].nil?
      record
    else
      bad_record = false
    end
  end

  def invalid_chars_rubymarc(record)
    good_chars = CHARSET
    curr_field = 0
    record.fields.each do |field|
      if field.class == MARC::DataField
        curr_subfield = 0
        field.subfields.each do |subfield|
          unless subfield.value.nil?
            temp_value = ""
            subfield.value.each_char do |c|
              if good_chars.include?(c.ord)
                temp_value << c
              else
                temp_value << "░#{c}░"
              end
            end
          end
          if temp_value.match(/░/)
            record.fields[curr_field].subfields[curr_subfield].value = temp_value
          end
          curr_subfield += 1
        end
      else
        unless field.value.nil?
          temp_value = ""
          field.value.each_char do |c|
            if good_chars.include?(c.ord)
              temp_value << c
            else
              temp_value << "░#{c}░"
            end
          end
          if temp_value.match(/░/)
            record.fields[curr_field].value = temp_value
          end
        end
      end
      curr_field += 1
    end
    if record.match(/░/)
      record
    else
      bad_record = false
    end
  end

  def empty_subfield_rubymarc(record)
    bad_record = false
    record.fields.each do |field|
      if field.class == MARC::DataField
        field.subfields.each do |subfield|
          if subfield.value == ''
            bad_record = true
          end
        end
      end
    end
    if bad_record
      record
    else
      bad_record
    end
  end

  def no_245_rubymarc(record)
    bad_record = true
    if record.fields.tag_list.include?("245")
      bad_record = false
    end
    if bad_record
      record
    else
      bad_record
    end
  end

  def composed_chars_rubymarc(record)
    bad_record = false
    unless record.to_s.unicode_normalized?(:nfd)
      bad_record = true
    end
    if bad_record
      record
    else
      bad_record
    end
  end

  def composed_chars_normalized_rubymarc(record)
    bad_record = false
    record.fields.each do |field|
      if field.class == MARC::DataField
        field.subfields.each do |subfield|
          subfield.value.each_codepoint do |c|
            if c < 1570 || (7680..10792).include?(c)
              unless c.chr(Encoding::UTF_8).unicode_normalized?(:nfd)
                bad_record = true
              end
            end
          end
          if subfield.value =~ /^.*[\u0653\u0654\u0655].*$/
            unless subfield.value.unicode_normalized?(:nfc)
              bad_record = true
            end
          end
        end
      else
        field.value.each_codepoint do |c|
          if c < 1570 || (7680..10792).include?(c)
            unless c.chr(Encoding::UTF_8).unicode_normalized?(:nfd)
              bad_record = true
            end
          end
        end
        if field.value =~ /^.*[\u0653\u0654\u0655].*$/
          unless field.value.unicode_normalized?(:nfc)
            bad_record = true
          end
        end
      end
    end
    if bad_record
      record
    else
      bad_record
    end
  end

  def relator_chars_rubymarc(record)
    bad_record = false
    record.fields.each do |field|
      if field.tag =~ /[17][01]0/
        field.subfields.each do |subfield|
          if subfield.code == 'e'
            if subfield.value =~ /.*[^a-z, \.].*/
              bad_record = true
            end
          end
        end
      elsif field.tag =~ /[17]11/
        field.subfields.each do |subfield|
          if subfield.code == 'j'
            if subfield.value =~ /.*[^a-z, \.].*/
              bad_record = true
            end
          end
        end
      end
    end
    if bad_record
      record
    else
      bad_record
    end
  end

  def x00_subfq_rubymarc(record)
    bad_record = false
    record.fields.each do |field|
      if field.tag =~ /[167]00/
        field.subfields.each do |subfield|
          if subfield.code = 'q'
            if subfield.value =~ /^(?!\([^\)]*\))$/
              bad_record = true
            end
          end
        end
      end
    end
    if bad_record
      record
    else
      bad_record
    end
  end

  def no_comma_x00_rubymarc(record)
    bad_record = false
    record.fields.each do |field|
      if field.tag =~ /[167]00/
        code_array = ''
        field.subfields.each do |subfield|
          code_array << subfield.code
        end
        subfx_d_index = code_array.index(/.d/)
        if subfx_d_index
          if field.subfields["#{subfx_d_index}"].value =~ /^.*[^,]$/
            bad_record = true
          end
        end
      end
    end
    if bad_record
      record
    else
      bad_record
    end
  end

  def relator_comma_rubymarc(record)
    bad_record = false
    record.fields.each do |field|
      tag = field.tag
      if tag =~ /[17][01][01]/
        code_array = ''
        field.subfields.each do |subfield|
          code_array << subfield.code
        end
        if tag =~ /[17][01]0/
          subfx_e_index = code_array.index(/.e/)
          if subfx_e_index
            if field.subfields["#{subfx_e_index}"].value =~ /^.*[^,]$/
              bad_record = true
            end
          end
        elsif tag =~ /[17]11/
          subfx_j_index = code_array.index(/.j/)
          if subfx_j_index
            if field.subfields["#{subfx_j_index}"].value =~ /^.*[^,]$/
              bad_record = true
            end
          end
        end
      end
    end
    if bad_record
      record
    else
      bad_record
    end
  end

  def heading_end_punct_rubymarc(record)
    bad_record = false
    record.fields.each do |field|
      if field.tag =~ /^[167][0-5].$|^8[013].$/
        unless field.indicator2 =~ /[47]/
          code_array = ''
          field.subfields.each do |subfield|
            code_array << subfield.code
          end
          last_heading_subfield_index = code_array.index(/[a-vx-z8][^a-vx-z8]*$/)
          if last_heading_subfield_index
            if field.subfields[last_heading_subfield_index].value =~ /.*[^\).\?\-]$/
              bad_record = true
            end
          end
        end
      end
    end
    if bad_record
      record
    else
      bad_record
    end
  end

  def extra_spaces_rubymarc(record)
    bad_record = false
    record.fields.each do |field|
      if field.class == MARC::DataField && field.tag != '010'
        if field.tag =~ /[1-469]..|0[2-9].|01[1-9]|7[0-5].|5[0-24-9].|53[0-24-9]/
          field.subfields.each do |subfield|
            if subfield.value =~ /^.*[[:blank:]]{2,}.*$|^.*[[:blank:]]+$|^[[:blank:]]+(.*)$/
              bad_record = true
            end
          end
        elsif field.tag == '533'
          field.subfields.each do |subfield|
            if subfield.code =~ /[^7]/
              if subfield.value =~ /^.*[[:blank:]]{2,}.*$|^.*[[:blank:]]+$|^[[:blank:]]+(.*)$/
                bad_record = true
              end
            end
          end
        elsif field.tag =~ /7[6-8]./
          field.subfields.each do |subfield|
            if subfield.code =~ /[a-v3-8]/
              if subfield.value =~ /^.*[[:blank:]]{2,}.*$|^.*[[:blank:]]+$|^[[:blank:]]+(.*)$/
                bad_record = true
              end
            end
          end
        elsif field.tag =~ /8../
          field.subfields.each do |subfield|
            if subfield.code =~ /[^w7]/
              if subfield.value =~ /^.*[[:blank:]]{2,}.*$|^.*[[:blank:]]+$/
                bad_record = true
              end
            end
          end
        end
      end
    end
    if bad_record
      record
    else
      bad_record
    end
  end

  def lowercase_headings_rubymarc(record)
    bad_record = false
    record.fields.each do |field|
      tag = field.tag
      if tag =~ /[167]../
        field.subfields.each do |subfield|
          if subfield.code == 'a'
            if subfield.value =~ /^[a-z]{3,}/
              bad_record = true
            end
          end
        end
      end
    end
    if bad_record
      record
    else
      bad_record
    end
  end

end
