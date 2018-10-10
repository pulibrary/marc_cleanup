module MarcCleanup
  def no_001?(record)
    record['001'].nil?
  end

  def non_repeatable_fields
    %w[
      001
      003
      005
      008
      010
      018
      036
      038
      040
      042
      043
      044
      045
      066
      100
      110
      111
      130
      240
      243
      245
      254
      256
      263
      306
      310
      357
      384
      507
      514
      841
      842
      844
      882
    ]
  end

  # https://www.oclc.org/bibformats/en/0xx/042.html
  def auth_codes_042
    %w[
      anuc
      dc
      dhca
      dlr
      gamma
      gils
      isds/c
      issnuk
      lcac
      lccopycat
      lccopycat-nm
      lcderive
      lchlas
      lcllh
      lcnccp
      lcnitrate
      lcnuc
      lcode
      msc
      nlc
      nlmcopyc
      nsdp
      nst
      ntccf
      pcc
      premarc
      reveal
      sanb
      scipio
      ukblcatcopy
      ukblsr
      ukscp
      xisds/c
      xissnuk
      xlc
      xnlc
      xnsdp
    ]
  end

  def auth_code_error?(record)
    return false unless record['042']
    auth_codes_042.include?(record['042']['a']) ? false : true
  end

  def fixed_field_char_errors?(record)
    fields = record.fields('001'..'009').map(&:value)
    bad_fields = fields.reject { |value| value.bytesize == value.chars.size }
    !bad_fields.empty?
  end

  def repeatable_field_errors?(record)
    field_count = record.fields.group_by(&:tag).map { |key, value| { tag: key, count: value.size } }
    nr_fields = field_count.select { |item| non_repeatable_fields.include?(item[:tag]) && item[:count] > 1 }
    !nr_fields.empty?
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
    record.fields('245').size != 1
  end

  def f245_subfield_errors?(record)
    fields = record.fields('245')
    return true if fields.empty?
    fields.each do |field|
      subfields = field.subfields.map(&:code)
      return true if subfields.count('a') != 1
      return true if subfields.count('b') > 1
      return true if subfields.count('c') > 1
    end
    false
  end

  def missing_040c?(record)
    return true unless record['040'] && record['040']['c']
    false
  end

  def bib_form(record)
    %w[a c d i j m p t].include?(record.leader[6]) ? record['008'].value[23] : record['008'].value[29]
  end

  def blvl_ab_valid?(record)
    record['773'] ? true : false
  end

  def ftype_ac_cdm_valid?(record)
    present_fields1 = record.fields(
      %w[
          020
          024
          027
          088
          100
          110
          111
          300
          533
          700
          710
          711
          800
          810
          811
          830
      ]
    )
    present_fields2 = record.fields(%w[260 264 533])
    return false if present_fields1.empty?
    return false if present_fields2.empty?
    f1_criteria = false
    present_fields1.each do |field|
      f1_criteria = true if field['a']
    end
    present_fields2.each do |field|
      case field.tag
      when '260'
        return true if field['a'] || field['b']
      when '264'
        return true if field['b']
      when '533'
        return true if field['c']
      end
    end
    false
  end

  def ftype_ac_is_valid?(record)
    present_fields = record.fields(%w[260 264 533])
    return false if present_fields.empty?
    present_fields.each do |field|
      case field.tag
      when '260'
        return true if field['a'] || field['b']
      when '264'
        return true if field['b']
      when '533'
        return true if field['c']
      end
    end
    false
  end

  def ftype_dt_cdm_valid?(record)
    present_fields = record.fields(
      %w[
          020
          024
          027
          028
          088
          100
          110
          111
          300
          533
          700
          710
          711
          800
          810
          811
          830
      ]
    )
    return false if present_fields.empty?
    present_fields.each do |field|
      case field.tag
      when '300'
        return true if field['a'] || field['f']
      when '533'
        return true if field['e']
      else
        return true if field['a']
      end
    end
    false
  end

  def ftype_e_cdims_valid?(record)
    present_fields1 = record.fields(%w[007 300 338])
    present_fields2 = record.fields(%w[260 264 533])
    return false if present_fields1.empty?
    return false if present_fields2.empty?
    f1_criteria = false
    present_fields1.each do |field|
      case field.tag
      when '007'
        f1_criteria = true if %w[a d r].include? field.value[0]
      when '300'
        f1_criteria = true if field['a']
      when '338'
        f1_criteria = true if field['a'] || field['b']
      when 533
        f1_criteria = true if field['e']
      end
    end
    return false unless f1_criteria
    present_fields2.each do |field|
      case field.tag
      when '260'
        return true if field['a'] || field['b']
      when '264'
        return true if field['b']
      when '533'
        return true if field['c']
      end
    end
    false
  end

  def ftype_f_cdm_valid?(record)
    present_fields = record.fields(
      %w[
          007
          300
          338
          533
      ]
    )
    return false if present_fields.empty?
    present_fields.each do |field|
      case field.tag
      when '007'
        return true if %w[a d r].include? field.value[0]
      when '300'
        return true if field['a'] || field['f']
      when '338'
        return true if field['a'] || field['b']
      when 533
        return true if field['e']
      end
    end
    false
  end

  def ftype_g_cdm_valid?(record)
    present_fields = record.fields(
      %w[
          007
          008
          300
          338
          345
          346
          538
      ]
    )
    return false if present_fields.empty?
    present_fields.each do |field|
      case field.tag
      when '007'
        return true if %w[a d r].include? field.value[0]
      when '008'
        return true if %w[g k o r].include?(record.leader[6]) && %w[f m p s t v].include?(field.value[33])
      when '300'
        return true if field['a']
      when '345'
        return true
      when '346'
        return true
      when '538'
        return true if field['a']
      end
    end
    false
  end

  def ftype_g_is_valid?(record)
    present_fields1 = record.fields(
      %w[
          007
          008
          300
          338
          345
          346
          538
      ]
    )
    present_fields2 = record.fields(%w[260 264 533])
    return false if present_fields1.empty?
    return false if present_fields2.empty?
    f1_criteria = false
    present_fields1.each do |field|
      case field.tag
      when '007'
        f1_criteria = true if %w[g m v].include? field.value[0]
      when '008'
        f1_criteria = true if %w[g k o r].include?(record.leader[6]) && %w[f m p s t v].include?(field.value[33])
      when '300'
        f1_criteria = true if field['a']
      when '338'
        f1_criteria = true if field['a'] || field['b']
      when '345'
        f1_criteria = true
      when '346'
        f1_criteria = true
      when 538
        f1_criteria = true if field['a']
      end
    end
    return false unless f1_criteria
    present_fields2.each do |field|
      case field.tag
      when '260'
        return true if field['a'] || field['b']
      when '264'
        return true if field['b']
      when '533'
        return true if field['c']
      end
    end
    false
  end

  def ftype_ij_cdm_valid?(record)
    present_fields = record.fields(
      %w[
          007
          300
          338
          344
          538
      ]
    )
    return false if present_fields.empty?
    present_fields.each do |field|
      case field.tag
      when '007'
        return true if field.value[0] == 's'
      when '300'
        return true if field['a']
      when '338'
        return true if field['a'] || field['b']
      when '344'
        return true
      when '538'
        return true if field['a']
      end
    end
    false
  end

  def ftype_ij_is_valid?(record)
    present_fields1 = record.fields(
      %w[
          007
          300
          338
          344
          538
      ]
    )
    present_fields2 = record.fields(%w[260 264 533])
    return false if present_fields1.empty?
    return false if present_fields2.empty?
    f1_criteria = false
    present_fields1.each do |field|
      case field.tag
      when '007'
        f1_criteria = true if field.value[0] == 's'
      when '300'
        f1_criteria = true if field['a']
      when '338'
        f1_criteria = true if field['a'] || field['b']
      when '344'
        f1_criteria = true
      when 538
        f1_criteria = true if field['a']
      end
    end
    return false unless f1_criteria
    present_fields2.each do |field|
      case field.tag
      when '260'
        return true if field['a'] || field['b']
      when '264'
        return true if field['b']
      when '533'
        return true if field['c']
      end
    end
    false
  end

  def ftype_k_cdm_valid?(record)
    present_fields = record.fields(
      %w[
          007
          008
          300
          338
      ]
    )
    return false if present_fields.empty?
    present_fields.each do |field|
      case field.tag
      when '007'
        return true if field.value[0] == 'k'
      when '008'
        return true if %w[g k o r].include?(record.leader[6]) && %w[a c k l n o p].include?(field.value[33])
      when '300'
        return true if field['a']
      when '338'
        return true if field['a'] || field['b']
      end
    end
    false
  end

  def ftype_k_is_valid?(record)
    present_fields1 = record.fields(
      %w[
          007
          008
          300
          338
      ]
    )
    present_fields2 = record.fields(%w[260 264 533])
    return false if present_fields1.empty?
    return false if present_fields2.empty?
    f1_criteria = false
    present_fields1.each do |field|
      case field.tag
      when '007'
        f1_criteria = true if field.value[0] == 'k'
      when '008'
        return true if %w[g k o r].include?(record.leader[6]) && %w[a c k l n o p].include?(field.value[33])
      when '300'
        f1_criteria = true if field['a']
      when '338'
        f1_criteria = true if field['a'] || field['b']
      end
    end
    return false unless f1_criteria
    present_fields2.each do |field|
      case field.tag
      when '260'
        return true if field['a'] || field['b']
      when '264'
        return true if field['b']
      when '533'
        return true if field['c']
      end
    end
    false
  end

  def ftype_m_cdm_valid?(record)
    present_fields = record.fields(
      %w[
        007
        300
        338
        347
        538
      ]
    )
    return false if present_fields.empty?
    present_fields.each do |field|
      case field.tag
      when '007'
        return true if field.value[0] == 'c'
      when '300'
        return true if field['a']
      when '338'
        return true if field['a'] || field['b']
      when '347'
        return true
      when '538'
        return true if field['a']
      end
    end
    false
  end

  def ftype_m_is_valid?(record)
    present_fields1 = record.fields(
      %w[
          007
          300
          338
          347
          538
      ]
    )
    present_fields2 = record.fields(%w[260 264 533])
    return false if present_fields1.empty?
    return false if present_fields2.empty?
    f1_criteria = false
    present_fields1.each do |field|
      case field.tag
      when '007'
        f1_criteria = true if field.value[0] == 'c'
      when '300'
        f1_criteria = true if field['a']
      when '338'
        f1_criteria = true if field['a'] || field['b']
      when '347'
        f1_criteria = true
      when '538'
        f1_criteria = true if field['a']
      end
    end
    return false unless f1_criteria
    present_fields2.each do |field|
      case field.tag
      when '260'
        return true if field['a'] || field['b']
      when '264'
        return true if field['b']
      when '533'
        return true if field['c']
      end
    end
    false
  end

  def ftype_or_cdm_valid?(record)
    present_fields = record.fields(
      %w[
          008
          300
          338
      ]
    )
    return false if present_fields.empty?
    present_fields.each do |field|
      case field.tag
      when '008'
        return true if %w[g k o r].include?(record.leader[6]) && %w[a b c d g q r w].include?(field.value[33])
      when '300'
        return true if field['a']
      when '338'
        return true if field['a'] || field['b']
      end
    end
    false
  end

  def ftype_or_is_valid?(record)
    present_fields1 = record.fields(
      %w[
          008
          300
          338
      ]
    )
    present_fields2 = record.fields(%w[260 264 533])
    return false if present_fields1.empty?
    return false if present_fields2.empty?
    f1_criteria = false
    present_fields1.each do |field|
      case field.tag
      when '008'
        return true if %w[g k o r].include?(record.leader[6]) && %w[a b c d g q r w].include?(field.value[33])
      when '300'
        f1_criteria = true if field['a']
      when '338'
        f1_criteria = true if field['a'] || field['b']
      end
    end
    return false unless f1_criteria
    present_fields2.each do |field|
      case field.tag
      when '260'
        return true if field['a'] || field['b']
      when '264'
        return true if field['b']
      when '533'
        return true if field['c']
      end
    end
    false
  end

  def ftype_p_cd_valid?(record)
    present_fields = record.fields(
      %w[
          100
          110
          111
          300
          338
          700
          710
          711
      ]
    )
    return false if present_fields.empty?
    present_fields.each do |field|
      case field.tag
      when '300'
        return true if field['a'] || field['f']
      when '338'
        return true if field['a'] || field['b']
      else
        return true if field['a']
      end
    end
    false
  end

  def sparse_record?(record)
    type = record.leader[6]
    blvl = record.leader[7]
    form = bib_form(record)
    return true unless %w[\  a b c d f o q r s].include?(form)
    valid =
      if %w[a b].include?(blvl)
        blvl_ab_valid?(record)
      elsif %w[a c].include?(type) && %w[c d m].include?(blvl)
        ftype_ac_cdm_valid?(record)
      elsif %w[a c].include?(type) && %w[i s].include?(blvl)
        ftype_ac_is_valid?(record)
      elsif %w[d t].include?(type) && %w[c d m].include?(blvl)
        ftype_dt_cdm_valid?(record)
      elsif %w[e].include?(type) && %w[c d i m s].include?(blvl)
        ftype_e_cdims_valid?(record)
      elsif %w[f].include?(type) && %w[c d m].include?(blvl)
        ftype_f_cdm_valid?(record)
      elsif %w[g].include?(type) && %w[c d m].include?(blvl)
        ftype_g_cdm_valid?(record)
      elsif %w[g].include?(type) && %w[i s].include?(blvl)
        ftype_g_is_valid?(record)
      elsif %w[i j].include?(type) && %w[c d m].include?(blvl)
        ftype_ij_cdm_valid?(record)
      elsif %w[i j].include?(type) && %w[i s].include?(blvl)
        ftype_ij_is_valid?(record)
      elsif %w[k].include?(type) && %w[c d m].include?(blvl)
        ftype_k_cdm_valid?(record)
      elsif %w[k].include?(type) && %w[i s].include?(blvl)
        ftype_k_is_valid?(record)
      elsif %w[m].include?(type) && %w[c d m].include?(blvl)
        ftype_m_cdm_valid?(record)
      elsif %w[m].include?(type) && %w[i s].include?(blvl)
        ftype_m_is_valid?(record)
      elsif %w[o r].include?(type) && %w[c d m].include?(blvl)
        ftype_or_cdm_valid?(record)
      elsif %w[o r].include?(type) && %w[i s].include?(blvl)
        ftype_or_is_valid?(record)
      elsif %w[p].include?(type) && %w[c d].include?(blvl)
        ftype_p_cd_valid?(record)
      else
        true
      end
    valid ? false : true
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
    (%w[130 240] - record.tags).empty?
  end

  def multiple_1xx?(record)
    record.fields('100'..'199').size > 1
  end

  def bad_utf8?(record)
    record.to_s.scrub != record.to_s
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
    pattern = /([^\p{L}\p{M}]\p{M}+)/
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
            good_chars.include?(c.ord) ? (temp_value << c) : (temp_value << '░' + c + '░')
          end
          record.fields[field_num].subfields[subf_num].value = temp_value
        end
      elsif record.fields[field_num].value
        temp_value = ''
        record.fields[field_num].value.each_char do |c|
          good_chars.include?(c.ord) ? (temp_value << c) : (temp_value << '░' + c + '░')
        end
        record.fields[field_num].value = temp_value
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
    record.fields(%w[100 600 700 800]).each do |field|
      field.subfields.each do |subfield|
        next unless subfield.code == 'q' && subfield.value =~ /^(?!\([^\)]*\))$/
        return true
      end
    end
    false
  end

  def no_comma_x00?(record)
    record.fields(%w[100 600 700 800]).each do |field|
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
      next unless field.tag =~ /[1678]../
      return true if field['a'] =~ /^[a-z]{3,}/
    end
    false
  end

  def subf_0_uri?(record)
    record.fields.each do |field|
      next unless field.class == MARC::DataField && field.tag =~ /^[^9]/ && field['0']
      field.subfields.each do |subfield|
        return true if subfield.code == '0' && subfield.value =~ /^\(uri\)/
      end
    end
    false
  end

  def bad_uri?(record)
    target_fields = record.fields('856')
    return false if target_fields.empty?
    target_fields.each do |field|
      next unless field['u']
      field.subfields.each do |subfield|
        next unless subfield.code == 'u'
        string = subfield.value
        return true unless URI.escape(URI.unescape(string).scrub) == string
      end
    end
    false
  end

  def multiple_no_008?(record)
    record.fields('008').size != 1
  end

  def place_codes
    [
      'aa ',
      'abc',
      'ac ',
      'aca',
      'ae ',
      'af ',
      'ag ',
      'ai ',
      'ai ',
      'air',
      'aj ',
      'ajr',
      'aku',
      'alu',
      'am ',
      'an ',
      'ao ',
      'aq ',
      'aru',
      'as ',
      'at ',
      'au ',
      'aw ',
      'ay ',
      'azu',
      'ba ',
      'bb ',
      'bcc',
      'bd ',
      'be ',
      'bf ',
      'bg ',
      'bh ',
      'bi ',
      'bl ',
      'bm ',
      'bn ',
      'bo ',
      'bp ',
      'br ',
      'bs ',
      'bt ',
      'bu ',
      'bv ',
      'bw ',
      'bwr',
      'bx ',
      'ca ',
      'cau',
      'cb ',
      'cc ',
      'cd ',
      'ce ',
      'cf ',
      'cg ',
      'ch ',
      'ci ',
      'cj ',
      'ck ',
      'cl ',
      'cm ',
      'cn ',
      'co ',
      'cou',
      'cp ',
      'cq ',
      'cr ',
      'cs ',
      'ctu',
      'cu ',
      'cv ',
      'cw ',
      'cx ',
      'cy ',
      'cz ',
      'dcu',
      'deu',
      'dk ',
      'dm ',
      'dq ',
      'dr ',
      'ea ',
      'ec ',
      'eg ',
      'em ',
      'enk',
      'er ',
      'err',
      'es ',
      'et ',
      'fa ',
      'fg ',
      'fi ',
      'fj ',
      'fk ',
      'flu',
      'fm ',
      'fp ',
      'fr ',
      'fs ',
      'ft ',
      'gau',
      'gb ',
      'gd ',
      'ge ',
      'gg ',
      'gh ',
      'gi ',
      'gl ',
      'gm ',
      'gn ',
      'go ',
      'gp ',
      'gr ',
      'gs ',
      'gsr',
      'gt ',
      'gu ',
      'gv ',
      'gw ',
      'gy ',
      'gz ',
      'hiu',
      'hk ',
      'hm ',
      'ho ',
      'ht ',
      'hu ',
      'iau',
      'ic ',
      'idu',
      'ie ',
      'ii ',
      'ilu',
      'im ',
      'inu',
      'io ',
      'iq ',
      'ir ',
      'is ',
      'it ',
      'iu ',
      'iv ',
      'iw ',
      'iy ',
      'ja ',
      'je ',
      'ji ',
      'jm ',
      'jn ',
      'jo ',
      'ke ',
      'kg ',
      'kgr',
      'kn ',
      'ko ',
      'ksu',
      'ku ',
      'kv ',
      'kyu',
      'kz ',
      'kzr',
      'lau',
      'lb ',
      'le ',
      'lh ',
      'li ',
      'lir',
      'ln ',
      'lo ',
      'ls ',
      'lu ',
      'lv ',
      'lvr',
      'ly ',
      'mau',
      'mbc',
      'mc ',
      'mdu',
      'meu',
      'mf ',
      'mg ',
      'mh ',
      'miu',
      'mj ',
      'mk ',
      'ml ',
      'mm ',
      'mnu',
      'mo ',
      'mou',
      'mp ',
      'mq ',
      'mr ',
      'msu',
      'mtu',
      'mu ',
      'mv ',
      'mvr',
      'mw ',
      'mx ',
      'my ',
      'mz ',
      'na ',
      'nbu',
      'ncu',
      'ndu',
      'ne ',
      'nfc',
      'ng ',
      'nhu',
      'nik',
      'nju',
      'nkc',
      'nl ',
      'nm ',
      'nmu',
      'nn ',
      'no ',
      'np ',
      'nq ',
      'nr ',
      'nsc',
      'ntc',
      'nu ',
      'nuc',
      'nvu',
      'nw ',
      'nx ',
      'nyu',
      'nz ',
      'ohu',
      'oku',
      'onc',
      'oru',
      'ot ',
      'pau',
      'pc ',
      'pe ',
      'pf ',
      'pg ',
      'ph ',
      'pic',
      'pk ',
      'pl ',
      'pn ',
      'po ',
      'pp ',
      'pr ',
      'pt ',
      'pw ',
      'py ',
      'qa ',
      'qea',
      'quc',
      'rb ',
      're ',
      'rh ',
      'riu',
      'rm ',
      'ru ',
      'rur',
      'rw ',
      'ry ',
      'sa ',
      'sb ',
      'sc ',
      'scu',
      'sd ',
      'sdu',
      'se ',
      'sf ',
      'sg ',
      'sh ',
      'si ',
      'sj ',
      'sk ',
      'sl ',
      'sm ',
      'sn ',
      'snc',
      'so ',
      'sp ',
      'sq ',
      'sr ',
      'ss ',
      'st ',
      'stk',
      'su ',
      'sv ',
      'sw ',
      'sx ',
      'sy ',
      'sz ',
      'ta ',
      'tar',
      'tc ',
      'tg ',
      'th ',
      'ti ',
      'tk ',
      'tkr',
      'tl ',
      'tma',
      'tnu',
      'to ',
      'tr ',
      'ts ',
      'tt ',
      'tu ',
      'tv ',
      'txu',
      'tz ',
      'ua ',
      'uc ',
      'ug ',
      'ui ',
      'uik',
      'uk ',
      'un ',
      'unr',
      'up ',
      'ur ',
      'us ',
      'utu',
      'uv ',
      'uy ',
      'uz ',
      'uzr',
      'vau',
      'vb ',
      'vc ',
      've ',
      'vi ',
      'vm ',
      'vn ',
      'vp ',
      'vra',
      'vs ',
      'vtu',
      'wau',
      'wb ',
      'wea',
      'wf ',
      'wiu',
      'wj ',
      'wk ',
      'wlk',
      'ws ',
      'wvu',
      'wyu',
      'xa ',
      'xb ',
      'xc ',
      'xd ',
      'xe ',
      'xf ',
      'xga',
      'xh ',
      'xi ',
      'xj ',
      'xk ',
      'xl ',
      'xm ',
      'xn ',
      'xna',
      'xo ',
      'xoa',
      'xp ',
      'xr ',
      'xra',
      'xs ',
      'xv ',
      'xx ',
      'xxc',
      'xxk',
      'xxr',
      'xxu',
      'ye ',
      'ykc',
      'ys ',
      'yu ',
      'za '
    ]
  end

  def lang_codes
    %w[
      aar
      abk
      ace
      ach
      ada
      ady
      afa
      afh
      afr
      ain
      ajm
      aka
      akk
      alb
      ale
      alg
      alt
      amh
      ang
      anp
      apa
      ara
      arc
      arg
      arm
      arn
      arp
      art
      arw
      asm
      ast
      ath
      aus
      ava
      ave
      awa
      aym
      aze
      bad
      bai
      bak
      bal
      bam
      ban
      baq
      bas
      bat
      bej
      bel
      bem
      ben
      ber
      bho
      bih
      bik
      bin
      bis
      bla
      bnt
      bos
      bra
      bre
      btk
      bua
      bug
      bul
      bur
      byn
      cad
      cai
      cam
      car
      cat
      cau
      ceb
      cel
      cha
      chb
      che
      chg
      chi
      chk
      chm
      chn
      cho
      chp
      chr
      chu
      chv
      chy
      cmc
      cnr
      cop
      cor
      cos
      cpe
      cpf
      cpp
      cre
      crh
      crp
      csb
      cus
      cze
      dak
      dan
      dar
      day
      del
      den
      dgr
      din
      div
      doi
      dra
      dsb
      dua
      dum
      dut
      dyu
      dzo
      efi
      egy
      eka
      elx
      eng
      enm
      epo
      esk
      esp
      est
      eth
      ewe
      ewo
      fan
      fao
      far
      fat
      fij
      fil
      fin
      fiu
      fon
      fre
      fri
      frm
      fro
      frr
      frs
      fry
      ful
      fur
      gaa
      gae
      gag
      gal
      gay
      gba
      gem
      geo
      ger
      gez
      gil
      gla
      gle
      glg
      glv
      gmh
      goh
      gon
      gor
      got
      grb
      grc
      gre
      grn
      gsw
      gua
      guj
      gwi
      hai
      hat
      hau
      haw
      heb
      her
      hil
      him
      hin
      hit
      hmn
      hmo
      hrv
      hsb
      hun
      hup
      iba
      ibo
      ice
      ido
      iii
      ijo
      iku
      ile
      ilo
      ina
      inc
      ind
      ine
      inh
      int
      ipk
      ira
      iri
      iro
      ita
      jav
      jbo
      jpn
      jpr
      jrb
      kaa
      kab
      kac
      kal
      kam
      kan
      kar
      kas
      kau
      kaw
      kaz
      kbd
      kha
      khi
      khm
      kho
      kik
      kin
      kir
      kmb
      kok
      kom
      kon
      kor
      kos
      kpe
      krc
      krl
      kro
      kru
      kua
      kum
      kur
      kus
      kut
      lad
      lah
      lam
      lan
      lao
      lap
      lat
      lav
      lez
      lim
      lin
      lit
      lol
      loz
      ltz
      lua
      lub
      lug
      lui
      lun
      luo
      lus
      mac
      mad
      mag
      mah
      mai
      mak
      mal
      man
      mao
      map
      mar
      mas
      max
      may
      mdf
      mdr
      men
      mga
      mic
      min
      mis
      mkh
      mla
      mlg
      mlt
      mnc
      mni
      mno
      moh
      mol
      mon
      mos
      mul
      mun
      mus
      mwl
      mwr
      myn
      myv
      nah
      nai
      nap
      nau
      nav
      nbl
      nde
      ndo
      nds
      nep
      new
      nia
      nic
      niu
      nno
      nob
      nog
      non
      nor
      nqo
      nso
      nub
      nwc
      nya
      nym
      nyn
      nyo
      nzi
      oci
      oji
      ori
      orm
      osa
      oss
      ota
      oto
      paa
      pag
      pal
      pam
      pan
      pap
      pau
      peo
      per
      phi
      phn
      pli
      pol
      pon
      por
      pra
      pro
      pus
      que
      raj
      rap
      rar
      roa
      roh
      rom
      rum
      run
      rup
      rus
      sad
      sag
      sah
      sai
      sal
      sam
      san
      sao
      sas
      sat
      scc
      scn
      sco
      scr
      sel
      sem
      sga
      sgn
      shn
      sho
      sid
      sin
      sio
      sit
      sla
      slo
      slv
      sma
      sme
      smi
      smj
      smn
      smo
      sms
      sna
      snd
      snh
      snk
      sog
      som
      son
      sot
      spa
      srd
      srn
      srp
      srr
      ssa
      sso
      ssw
      suk
      sun
      sus
      sux
      swa
      swe
      swz
      syc
      syr
      tag
      tah
      tai
      taj
      tam
      tar
      tat
      tel
      tem
      ter
      tet
      tgk
      tgl
      tha
      tib
      tig
      tir
      tiv
      tkl
      tlh
      tli
      tmh
      tog
      ton
      tpi
      tru
      tsi
      tsn
      tso
      tsw
      tuk
      tum
      tup
      tur
      tut
      tvl
      twi
      tyv
      udm
      uga
      uig
      ukr
      umb
      und
      urd
      uzb
      vai
      ven
      vie
      vol
      vot
      wak
      wal
      war
      was
      wel
      wen
      wln
      wol
      xal
      xho
      yao
      yap
      yid
      yor
      ypk
      zap
      zbl
      zen
      zha
      znd
      zul
      zun
      zxx
      zza
    ]
  end

  def illus_codes
    /^[ a-mop]+$/
  end

  def audience_codes
    /[ a-gj|]/
  end

  def item_form_codes
    /[ a-dfoq-s|]/
  end

  def item_orig_form_codes
    /[ a-foqs|]/
  end

  def contents_codes
    /^[ a-gi-wyz256]+$/
  end

  def gov_pub_codes
    /[ acfilmosuz|]/
  end

  def lit_form_codes
    /[01c-fhijmpsu|]/
  end

  def biog_codes
    /[ abcd|]/
  end

  def comp_type_codes
    /[a-jmuz|]/
  end

  def relief_codes
    /^[ a-gi-kmz]+$/
  end

  def proj_codes
    [
      '  ',
      'aa',
      'ab',
      'ac',
      'ad',
      'ae',
      'af',
      'ag',
      'am',
      'an',
      'ap',
      'au',
      'az',
      'ba',
      'bb',
      'bc',
      'bd',
      'be',
      'bf',
      'bg',
      'bh',
      'bi',
      'bj',
      'bk',
      'bl',
      'bo',
      'br',
      'bs',
      'bu',
      'bz',
      'ca',
      'cb',
      'cc',
      'ce',
      'cp',
      'cu',
      'cz',
      'da',
      'db',
      'dc',
      'dd',
      'de',
      'df',
      'dg',
      'dh',
      'dl',
      'zz',
      '||'
    ]
  end

  def map_type_codes
    /[a-guz|]/
  end

  def map_special_format_codes
    /[ ejklnoprz]+/
  end

  def comp_codes_uris
    {
      'an' => 'gf2014026635',
      'bd' => 'gf2014026648',
      'bg' => 'gf2014026664',
      'bl' => 'gf2014026665',
      'bt' => 'gf2014026650',
      'ca' => 'gf2014026701',
      'cb' => 'gf2014026707',
      'cc' => 'gf2014026707',
      'cg' => 'gf2014026724',
      'ch' => 'gf2014026713',
      'cl' => 'gf2014026712',
      'cn' => 'gf2014026687',
      'co' => 'gf2014026725',
      'cp' => 'gf2014027007',
      'cr' => 'gf2014026695',
      'cs' => 'gf2014026624',
      'ct' => 'gf2014026688',
      'cy' => 'gf2014026739',
      'dv' => 'gf2014027116',
      'fg' => 'gf2014026818',
      'fl' => 'gf2014026806',
      'fm' => 'gf2014026809',
      'ft' => 'gf2018026018',
      'gm' => 'gf2014026839',
      'hy' => 'gf2014026872',
      'jz' => 'gf2014026879',
      'mc' => 'gf2014027050',
      'md' => 'gf2014026915',
      'mi' => 'gf2014026940',
      'mo' => 'gf2014026949',
      'mp' => 'gf2014026950',
      'mr' => 'gf2014026922',
      'ms' => 'gf2014026926',
      'mz' => 'gf2014026928',
      'nc' => 'gf2017026144',
      'op' => 'gf2014026976',
      'or' => 'gf2014026977',
      'ov' => 'gf2014026980',
      'pg' => 'gf2014027017',
      'pm' => 'gf2014026861',
      'po' => 'gf2014027005',
      'pp' => 'gf2014027009',
      'pr' => 'gf2014027013',
      'ps' => 'gf2014026989',
      'pt' => 'gf2014026984',
      'pv' => 'gf2014026994',
      'rc' => 'gf2014027054',
      'rd' => 'gf2014027057',
      'rg' => 'gf2014027034',
      'ri' => 'gf2017026128',
      'rp' => 'gf2014027051',
      'rq' => 'gf2014027048',
      'sd' => 'gf2014027111',
      'sg' => 'gf2014027103',
      'sn' => 'gf2014027099',
      'sp' => 'gf2014027120',
      'st' => 'gf2014027115',
      'su' => 'gf2014027116',
      'sy' => 'gf2014027121',
      'tc' => 'gf2014027140',
      'vi' => 'gf2017026025',
      'vr' => 'gf2014027156',
      'wz' => 'gf2014027167',
      'za' => 'gf2016026059'
    }
  end

  def composition_codes
    %w[
      an
      bd
      bg
      bl
      bt
      ca
      cb
      cc
      cg
      ch
      cl
      cn
      co
      cp
      cr
      cs
      ct
      cy
      cz
      df
      dv
      fg
      fl
      fm
      ft
      gm
      hy
      jz
      mc
      md
      mi
      mo
      mp
      mr
      ms
      mu
      mz
      nc
      nn
      op
      or
      ov
      pg
      pm
      po
      pp
      pr
      ps
      pt
      pv
      rc
      rd
      rg
      ri
      rp
      rq
      sd
      sg
      sn
      sp
      st
      su
      sy
      tc
      tl
      ts
      uu
      vi
      vr
      wz
      za
      zz
      ||
    ]
  end

  def music_format_codes
    /[a-eg-npuz|]/
  end

  def music_part_codes
    /[ defnu|]/
  end

  def accompany_codes
    /^[ a-ikrsz]+$/
  end

  def lit_text_codes
    /^[ a-prstz]+$/
  end

  def transpose_codes
    /[ abcnu|]/
  end

  def freq_codes
    /[ a-kmqstuwz|]/
  end

  def cr_type_codes
    /[ dlmnpw|]/
  end

  def cr_contents_codes
    /^[ a-ik-wyz56]+/
  end

  def orig_script_codes
    /[ a-luz|]/
  end

  def visual_type_codes
    /^[a-dfgik-tvwz|]$/
  end

  def all_008(field)
    date_entered = field[0..5]
    date_type = field[6]
    date1 = field[7..10]
    date2 = field[11..14]
    place = field[15..17]
    lang = field[35..37]
    modified = field[38]
    cat_source = field[39]
    return true unless date_entered =~ /^[0-9]{6}$/
    return true unless %w[b c d e i k m n p q r s t u |].include?(date_type)
    return true unless date1 == '||||' || date1 == '    '  || date1 =~ /^[0-9u]{4}$/
    return true unless date2 == '||||' || date2 == '    '  || date2 =~ /^[0-9u]{4}$/
    return true unless place == '|||' || place_codes.include?(place)
    return true unless lang == '|||'  || lang_codes.include?(lang)
    return true unless %w[\  d o r s x |].include?(modified)
    return true unless %w[\  c d u |].include?(cat_source)
    false
  end

  def book_008(field)
    illus = field[0..3]
    audience = field[4]
    item_form = field[5]
    contents = field[6..9]
    gov_pub = field[10]
    conf_pub = field[11]
    festschrift = field[12]
    index = field[13]
    undefined = field[14]
    lit_form = field[15]
    biog = field[16]
    return true unless illus == '||||' || illus =~ illus_codes
    return true unless audience =~ audience_codes
    return true unless item_form =~ item_form_codes
    return true unless contents == '||||' || contents =~ contents_codes
    return true unless gov_pub =~ gov_pub_codes
    return true unless %w[0 1 |].include?(conf_pub)
    return true unless %w[0 1 |].include?(festschrift)
    return true unless %w[0 1 |].include?(index)
    return true unless undefined == ' '
    return true unless lit_form =~ lit_form_codes
    return true unless biog =~ biog_codes
    false
  end

  def comp_008(field)
    undef1 = field[0..3]
    audience = field[4]
    item_form = field[5]
    undef2 = field[6..7]
    type = field[8]
    undef3 = field[9]
    gov_pub = field[10]
    undef4 = field[11..16]
    return true unless ['||||', '    '].include?(undef1)
    return true unless audience =~ audience_codes
    return true unless item_form =~ /[ oq|]/
    return true unless ['  ', '||'].include?(undef2)
    return true unless type =~ comp_type_codes
    return true unless %w[\  |].include?(undef3)
    return true unless gov_pub =~ gov_pub_codes
    return true unless ['||||||', '      '].include?(undef4)
    false
  end

  def map_008(field)
    relief = field[0..3]
    proj = field[4..5]
    undef1 = field[6]
    type = field[7]
    undef2 = field[8..9]
    gov_pub = field[10]
    item_form = field[11]
    undef3 = field[12]
    index = field[13]
    undef4 = field[14]
    format = field[15..16]
    return true unless relief == '||||' || relief =~ relief_codes
    return true unless proj_codes.include?(proj)
    return true unless [' ', '|'].include?(undef1)
    return true unless type =~ map_type_codes
    return true unless ['||', '  '].include?(undef2)
    return true unless gov_pub =~ gov_pub_codes
    return true unless item_form =~ item_form_codes
    return true unless [' ', '|'].include?(undef3)
    return true unless %w[0 1 |].include?(index)
    return true unless [' ', '|'].include?(undef4)
    return true unless format == '||' || format =~ map_special_format_codes
    false
  end

  def music_008(field)
    comp_form = field[0..1]
    music_format = field[2]
    parts = field[3]
    audience = field[4]
    item_form = field[5]
    accompanying = field[6..11]
    lit_text = field[12..13]
    undef1 = field[14]
    transpose = field[15]
    undef2 = field[16]
    return true unless composition_codes.include?(comp_form)
    return true unless music_format =~ music_format_codes
    return true unless parts =~ music_part_codes
    return true unless audience =~ audience_codes
    return true unless item_form =~ item_form_codes
    return true unless accompanying == '||||||' || accompanying =~ accompany_codes
    return true unless lit_text == '||' || lit_text =~ lit_text_codes
    return true unless [' ', '|'].include?(undef1)
    return true unless transpose =~ transpose_codes
    return true unless [' ', '|'].include?(undef2)
    false
  end

  def continuing_resource_008(field)
    freq = field[0]
    reg = field[1]
    undef1 = field[2]
    cr_type = field[3]
    item_orig_form = field[4]
    item_form = field[5]
    work_nature = field[6]
    contents = field[7..9]
    gov_pub = field[10]
    conf_pub = field[11]
    undef2 = field[12..14]
    orig_script = field[15]
    entry = field[16]
    return true unless freq =~ freq_codes
    return true unless %w[n r u x |].include?(reg)
    return true unless [' ', '|'].include?(undef1)
    return true unless cr_type =~ cr_type_codes
    return true unless item_orig_form =~ item_orig_form_codes
    return true unless item_form =~ item_form_codes
    return true unless work_nature == '|' || work_nature =~ cr_contents_codes
    return true unless contents == '|||' || contents =~ cr_contents_codes
    return true unless gov_pub =~ gov_pub_codes
    return true unless ['0', '1', '|'].include?(conf_pub)
    return true unless ['   ', '|||'].include?(undef2)
    return true unless orig_script =~ orig_script_codes
    return true unless %w[0 1 2 |].include?(entry)
    false
  end

  def visual_008(field)
    runtime = field[0..2]
    undef1 = field[3]
    audience = field[4]
    undef2 = field[5..9]
    gov_pub = field[10]
    item_form = field[11]
    undef3 = field[12..14]
    visual_type = field[15]
    technique = field[16]
    return true unless %w[nnn --- |||].include?(runtime) || runtime =~ /^[0-9]{3}$/
    return true unless [' ', '|'].include?(undef1)
    return true unless audience =~ audience_codes
    return true unless ['     ', '|||||'].include?(undef2)
    return true unless gov_pub =~ gov_pub_codes
    return true unless item_form =~ item_form_codes
    return true unless ['   ', '|||'].include?(undef3)
    return true unless visual_type =~ visual_type_codes
    return true unless %w[a c l n u z |].include?(technique)
  end

  def mix_mat_008(field)
    undef1 = field[0..4]
    item_form = field[5]
    undef2 = field[6..16]
    return true unless ['     ', '|||||'].include?(undef1)
    return true unless item_form =~ item_form_codes
    return true unless ['           ', '|||||||||||'].include?(undef2)
    false
  end

  def book
    %w[
      aa
      ac
      ad
      am
      ta
      tc
      td
      tm
    ]
  end

  def comp_file
    %w[
      ma
      mb
      mc
      md
      mi
      mm
      ms
    ]
  end

  def map
    %w[
      ea
      eb
      ec
      ed
      ei
      em
      es
      fa
      fb
      fc
      fd
      fi
      fm
      fs
    ]
  end

  def music
    %w[
      ca
      cb
      cc
      cd
      ci
      cm
      cs
      da
      db
      dc
      dd
      di
      dm
      ds
      ia
      ib
      ic
      id
      ii
      im
      is
      ja
      jb
      jc
      jd
      ji
      jm
      js
    ]
  end

  def continuing_resource
    %w[
      ab
      ai
      as
      tb
      ti
      ts
    ]
  end

  def visual
    %w[
      ga
      gb
      gc
      gd
      gi
      gm
      gs
      ka
      kb
      kc
      kd
      ki
      km
      ks
      oa
      ob
      oc
      od
      oi
      om
      os
      ra
      rb
      rc
      rd
      ri
      rm
      rs
    ]
  end

  def mixed
    %w[
      pa
      pb
      pc
      pd
      pi
      pm
      ps
    ]
  end

  def bad_008?(record)
    field = record['008'].value
    return true if field.length != 40
    return true if all_008(field)
    rec_type = record.leader[6..7]
    specific_f008 = field[18..34]
    if book.include?(rec_type)
      return true if book_008(specific_f008)
    elsif comp_file.include?(rec_type)
      return true if comp_008(specific_f008)
    elsif map.include?(rec_type)
      return true if map_008(specific_f008)
    elsif music.include?(rec_type)
      return true if music_008(specific_f008)
    elsif continuing_resource.include?(rec_type)
      return true if continuing_resource_008(specific_f008)
    elsif visual.include?(rec_type)
      return true if visual_008(specific_f008)
    elsif mixed.include?(rec_type)
      return true if mix_mat_008(specific_f008)
    end
    false
  end
end
