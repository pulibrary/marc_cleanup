module MarcCleanup
  def non_repeatable_field_errors?(record:, schema: RECORD_SCHEMA)
    field_count = record.fields.group_by(&:tag).map { |key, value| { tag: key, count: value.size } }
    nr_fields = field_count.select do |field|
      field[:count] > 1 &&
      schema[field[:tag]] &&
      schema[field[:tag]]['repeat'] == false
    end
    !nr_fields.empty?
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

  ### Count fields in a record; set :subfields to True to drill down to subfields
  def field_count(record, opts = {})
    results = {}
    if opts[:subfields]
      record.fields.each do |field|
        tag = field.tag.scrub('')
        case tag
        when /^00/
          results[tag] = 0 unless results[tag]
          results[tag] += 1
        else
          field.subfields.each do |subfield|
            key = tag + subfield.code.to_s.scrub('')
            results[key] = 0 unless results[key]
            results[key] += 1
          end
        end
      end
    else
      record.fields.each do |field|
        tag = field.tag.scrub('')
        results[tag] = 0 unless results[tag]
        results[tag] += 1
      end
    end
    results
  end

  ### Scrub invalid UTF-8 byte sequences within field values,
  #     replacing with nothing; indicators, subfield codes, and tags must be
  #     handled separately
  def bad_utf8_fix(record)
    record.fields.each do |field|
      field_index = record.fields.index(field)
      if field.class == MARC::DataField
        field.subfields.each do |subfield|
          subfield_index = record.fields[field_index].subfields.index(subfield)
          record.fields[field_index].subfields[subfield_index].value.scrub!('').force_encoding('UTF-8')
        end
      else
        record.fields[field_index].value.scrub!('').force_encoding('UTF-8')
      end
    end
    record
  end

  ### Replace invalid XML 1.0 characters with a space
  def invalid_xml_fix(record)
    bad_xml_range = /[\u0000-\u0008\u000B\u000C\u000E-\u001C\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF]/
    record.leader.gsub!(bad_xml_range, ' ')
    record.fields.each do |field|
      field_index = record.fields.index(field)
      if field.class == MARC::DataField
        curr_subfield = 0
        final_subfield = field.subfields.length
        while curr_subfield < final_subfield
          record.fields[field_index].subfields[curr_subfield].value.gsub!(bad_xml_range, ' ')
          curr_subfield += 1
        end
      else
        record.fields[field_index].value.gsub!(bad_xml_range, ' ')
      end
    end
    record
  end

  ### Replace tab and newline characters with a space
  def tab_newline_fix(record)
    regex = /[\x09\n\r]/
    record.leader.gsub!(regex, ' ')
    record.fields.each do |field|
      field_index = record.fields.index(field)
      if field.class == MARC::DataField
        curr_subfield = 0
        final_subfield = field.subfields.length
        field.indicator1.gsub!(regex, ' ') if field.indicator1
        field.indicator2.gsub!(regex, ' ') if field.indicator2
        while curr_subfield < final_subfield
          record.fields[field_index].subfields[curr_subfield].value.gsub!(regex, ' ')
          curr_subfield += 1
        end
      else
        record.fields[field_index].value.gsub!(regex, ' ')
      end
    end
    record
  end

  ## Can delete fields based on tags alone, or with
  ## optional indicator values provided in arrays
  def field_delete(tags, record, indicators = {})
    if indicators.empty?
      record.fields.delete_if { |field| tags.include? field.tag }
    else
      ind_1 = indicators[:ind_1]
      ind_2 = indicators[:ind_2]
      if ind_1 && ind_2
        record.fields.delete_if { |field| (tags.include? field.tag) && (ind_1.include? field.indicator1) && (ind_2.include? field.indicator2) }
      elsif ind_1
        record.fields.delete_if { |field| (tags.include? field.tag) && (ind_1.include? field.indicator1) }
      else
        record.fields.delete_if { |field| (tags.include? field.tag) && (ind_2.include? field.indicator2) }
      end
    end
    record
  end

  def recap_fixes(record)
    record = bad_utf8_fix(record)
    record = field_delete(['959'], record)
    record = field_delete(['856'], record)
    record = leaderfix(record)
    record = extra_space_fix(record)
    record = invalid_xml_fix(record)
    record = composed_chars_normalize(record)
    record = tab_newline_fix(record)
    empty_subfield_fix(record)
  end

  ### Remove field from a record that matches a string version of the field
  ###   generated by ruby-marc (ex.: '655  0 $a Electronic books')
  def remove_field(field_string, record)
    orig_string = field_string.dup
    orig_string.scrub!('')
    orig_string.strip!
    field_tag = orig_string[0..2]
    target_fields = record.fields(field_tag)
    return record if target_fields.empty?

    target_fields.each do |field|
      string = field.to_s
      string.scrub!('')
      string.strip!
      next unless string == orig_string

      field_index = record.fields.index(field)
      record.fields.delete_at(field_index)
    end
    record
  end

  def replace_field_targets(record:, start_pos:, case_sensitive:, source_field:)
    source_field_content = source_field.to_s[start_pos..]
    if case_sensitive
      record.fields(source_field.tag).select do |field|
        field.to_s[start_pos..] == source_field_content
      end
    else
      record.fields(source_field.tag).select do |field|
        field.to_s[start_pos..].casecmp?(source_field_content)
      end
    end
  end

  ### Replace field from a record that matches a supplied source field
  ###   with the supplied replacement field, which can be either a ControlField
  ###   or a DataField
  def replace_field(source_field:, replacement_field:, record:, ignore_indicators: false, case_sensitive: true)
    start_pos = field_content_start(source_field: source_field,
                                    ignore_indicators: ignore_indicators)
    target_fields = replace_field_targets(record: record,
                                          source_field: source_field,
                                          start_pos: start_pos,
                                          case_sensitive: case_sensitive)
    target_fields.each do |field|
      field_index = record.fields.index(field)
      record.fields[field_index] = replacement_field
    end
    record
  end

  def field_content_start(source_field:, ignore_indicators:)
    if ignore_indicators && source_field.instance_of?(MARC::DataField)
      7
    else
      4
    end
  end

  ### Perform multiple field replacements on a record;
  ###   input is an array of hashes with the following attributes:
  ###   - source_field: ruby-marc field (DataField or ControlField)
  ###   - replacement_field: ruby-marc field (DataField or ControlField)
  ###   - ignore_indicators: optional Boolean to specify whether to ignore
  ###     indicators for this replacement
  ###   - case_sensitive: optional Boolean to specify whether matching
  ###     should be case-sensitive
  def replace_fields(field_array:, record:)
    field_array.each do |replacement|
      replacement[:ignore_indicators] = false unless replacement.key?(:ignore_indicators)
      replacement[:case_sensitive] = true unless replacement.key?(:case_sensitive)
      record = replace_field(source_field: replacement[:source_field],
                             replacement_field: replacement[:replacement_field],
                             record: record,
                             ignore_indicators: replacement[:ignore_indicators],
                             case_sensitive: replacement[:case_sensitive])
    end
    record
  end

  ### Default field sort: sort fixed fields numerically, then sort the rest
  ###   in groups, leaving the order of fields within the group alone
  def field_sort(record)
    new_rec = MARC::Record.new
    new_rec.leader = record.leader
    record.fields('001'..'009').sort_by { |field| field.tag }.each do |field|
      new_rec.append(field)
    end
    record.fields('010'..'099').each do |field|
      new_rec.append(field)
    end
    record.fields('100'..'199').each do |field|
      new_rec.append(field)
    end
    record.fields('200'..'299').each do |field|
      new_rec.append(field)
    end
    record.fields('300'..'399').each do |field|
      new_rec.append(field)
    end
    record.fields('400'..'499').each do |field|
      new_rec.append(field)
    end
    record.fields('500'..'599').each do |field|
      new_rec.append(field)
    end
    record.fields('600'..'699').each do |field|
      new_rec.append(field)
    end
    record.fields('700'..'799').each do |field|
      new_rec.append(field)
    end
    record.fields('800'..'899').each do |field|
      new_rec.append(field)
    end
    record.fields('900'..'999').each do |field|
      new_rec.append(field)
    end
    new_rec
  end

  def remove_duplicate_fields(record)
    field_array = []
    record.fields.reverse_each do |field|
      field_index = record.fields.index(field)
      string = field.to_s
      if field_array.include?(string)
        record.fields.delete_at(field_index)
      else
        field_array << string
      end
    end
    record
  end

  ### Duplicate record to preserve original when making modifications
  def duplicate_record(record)
    raw_marc = ''
    writer = MARC::Writer.new(StringIO.new(raw_marc, 'w'))
    writer.write(record)
    writer.close
    reader = MARC::Reader.new(StringIO.new(raw_marc, 'r'),
                              external_encoding: 'UTF-8',
                              invalid: :replace,
                              replace: '')
    reader.first
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
    present_fields1 = record.fields(%w[007 300 338 533])
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
      when '533'
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
      when '533'
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
    return false if present_fields2.empty?

    f1_criteria = false
    present_fields1.each do |field|
      case field.tag
      when '007'
        f1_criteria = true if %w[g m v].include? field.value[0]
      when '008'
        f1_criteria = true if %w[f m p s t v].include?(field.value[33])
      when '300'
        f1_criteria = true if field['a']
      when '338'
        f1_criteria = true if field['a'] || field['b']
      when '345'
        f1_criteria = true
      when '346'
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

  def ftype_k_cdm_valid?(record)
    present_fields = record.fields(
      %w[
        007
        008
        300
        338
      ]
    )
    present_fields.each do |field|
      case field.tag
      when '007'
        return true if field.value[0] == 'k'
      when '008'
        return true if %w[a c k l n o p].include?(field.value[33])
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
    return false if present_fields2.empty?

    f1_criteria = false
    present_fields1.each do |field|
      case field.tag
      when '007'
        f1_criteria = true if field.value[0] == 'k'
      when '008'
        return true if %w[a c k l n o p].include?(field.value[33])
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
    present_fields.each do |field|
      case field.tag
      when '008'
        return true if %w[a b c d g q r w].include?(field.value[33])
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
    return false if present_fields2.empty?

    f1_criteria = false
    present_fields1.each do |field|
      case field.tag
      when '008'
        return true if %w[a b c d g q r w].include?(field.value[33])
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

  def bib_form(record)
    %w[a c d i j m p t].include?(record.leader[6]) ? record['008'].value[23] : record['008'].value[29]
  end

  def sparse_record?(record)
    return true unless record.fields('008').size == 1

    type = record.leader[6]
    blvl = record.leader[7]
    form = bib_form(record)
    return true unless %w[\  a b c d f o q r s].include?(form)

    f245 = record['245']
    return true unless f245 && (f245['a'] || f245['k'])

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

  ### `schema` is a YAML file loaded as a hash;
  ### schema = YAML.load_file("#{ROOT_DIR}/lib/marc_cleanup/variable_field_schema.yml")
  def validate_marc(record:, schema: RECORD_SCHEMA)
    hash = {}
    hash[:multiple_1xx] = multiple_1xx?(record)
    hash[:has_130_240] = has_130_240?(record)
    hash[:multiple_no_245] = multiple_no_245?(record)
    hash[:non_repeatable_field_errors] = non_repeatable_field_errors?(record: record, schema: schema)
    hash[:invalid_tags] = record.fields.select do |field|
      field.class == MARC::DataField &&
      field.tag[0] != '9' &&
      !schema.keys.include?(field.tag)
    end.map { |f| f.tag }
    hash[:invalid_fields] = {}
    record.fields('010'..'899').each do |field|
      next unless schema[field.tag]

      field_num = record.fields(field.tag).index { |f| field }
      field_num += 1
      tag = field.tag
      if field.tag == '880'
        linked_field = field.subfields.select { |s| s.code == '6' }
        if linked_field.empty?
          error = "No field linkage in instance #{field_num} of 880"
          hash[:invalid_fields][field.tag] ||= []
          hash[:invalid_fields][field.tag] << error
        elsif linked_field.size > 1
          error = "Multiple field links in instance #{field_num} of 880"
          hash[:invalid_fields][field.tag] ||= []
          hash[:invalid_fields][field.tag] << error
        elsif field['6'] !~ /^[0-9]{3}-[0-9]+/
          error = "Invalid field linkage in instance #{field_num} of 880"
          hash[:invalid_fields][field.tag] ||= []
          hash[:invalid_fields][field.tag] << error
        else
          tag = field['6'].gsub(/^([0-9]{3})-.*$/, '\1')
          unless schema[tag]
            error = "Invalid linked field tag #{tag} in instance #{field_num} of 880"
            hash[:invalid_fields][field.tag] ||= []
            hash[:invalid_fields][field.tag] << error
          end
        end
      end
      next unless schema[tag]

      unless schema[tag]['ind1'].include?(field.indicator1.to_s)
        error = "Invalid indicator1 value #{field.indicator1.to_s} in instance #{field_num}"
        hash[:invalid_fields][field.tag] ||= []
        hash[:invalid_fields][field.tag] << error
      end
      unless schema[tag]['ind2'].include?(field.indicator2.to_s)
        error = "Invalid indicator2 value #{field.indicator2.to_s} in instance #{field_num}"
        hash[:invalid_fields][field.tag] ||= []
        hash[:invalid_fields][field.tag] << error
      end
      subf_hash = {}
      field.subfields.each do |subfield|
        subf_hash[subfield.code] ||= 0
        subf_hash[subfield.code] += 1
      end
      subf_hash.each do |code, count|
        if schema[tag]['subfields'][code].nil?
          hash[:invalid_fields][field.tag] ||= []
          hash[:invalid_fields][field.tag] << "Invalid subfield code #{code} in instance #{field_num}"
        elsif schema[tag]['subfields'][code]['repeat'] == false && count > 1
          hash[:invalid_fields][field.tag] ||= []
          hash[:invalid_fields][field.tag] << "Non-repeatable subfield code #{code} repeated in instance #{field_num}"
        end
      end
    end
    hash
  end

  ### When the 040$e says rda, position 18 of the leader must be c or i.
  def rda_convention_mismatch(record)
    rda040 = record.fields('040').select { |field| field['e'] == 'rda' }
    !rda040.empty? && !%w[c i].include?(record.leader[18])
  end

  def rda_convention_correction(record)
    if rda_convention_mismatch(record) == true
      record.leader[18] = "i"
    end
    record
  end

end
