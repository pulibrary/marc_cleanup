# frozen_string_literal: true

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

  def bad_utf8_scrub_datafield(field)
    new_field = MARC::DataField.new(field.tag,
                                    field.indicator1,
                                    field.indicator2)
    field.subfields.each do |subfield|
      new_value = bad_utf8_scrub_value(subfield.value)
      new_subfield = MARC::Subfield.new(subfield.code, new_value)
      new_field.append(new_subfield)
    end
    new_field
  end

  def bad_utf8_scrub_value(string)
    string.scrub('').force_encoding('UTF-8')
  end

  ### Scrub invalid UTF-8 byte sequences within field values,
  #     replacing with nothing; indicators, subfield codes, and tags must be
  #     handled separately
  def bad_utf8_scrub(record)
    record.fields.each_with_index do |field, field_index|
      if field.instance_of?(MARC::DataField)
        record.fields[field_index] = bad_utf8_scrub_datafield(field)
      else
        record.fields[field_index].value = bad_utf8_scrub_value(field.value)
      end
    end
    record
  end

  def bad_utf8_identify_value(string)
    string.scrub { |bytes| "░#{bytes.unpack1('H*')}░" }
          .force_encoding('UTF-8')
  end

  def bad_utf8_identify_controlfield(field)
    new_value = bad_utf8_identify_value(field.value)
    MARC::ControlField.new(field.tag, new_value)
  end

  def bad_utf8_identify_datafield(field)
    new_field = MARC::DataField.new(field.tag)
    new_field.indicator1 = field.indicator1
    new_field.indicator2 = field.indicator2
    field.subfields.each do |subfield|
      new_value = bad_utf8_identify_value(subfield.value)
      new_field.append(MARC::Subfield.new(subfield.code, new_value))
    end
    new_field
  end

  def bad_utf8_identify(record)
    record.fields.each_with_index do |field, field_index|
      record.fields[field_index] = if field.instance_of?(MARC::DataField)
                                     bad_utf8_identify_datafield(field)
                                   else
                                     bad_utf8_identify_controlfield(field)
                                   end
    end
    record
  end

  def tab_newline_char?(record)
    pattern = /[\x09\n\r]/
    return true if record.leader =~ pattern

    record.fields.any? do |field|
      field.to_s =~ pattern
    end
  end

  def invalid_xml_identify_value(string)
    regex = /[\u0000-\u0008\u000B\u000C\u000E-\u001C\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF]/
    new_string = ''.dup
    string.chars.each do |char|
      new_string << if char =~ regex
                      "░#{char}░"
                    else
                      char
                    end
    end
    new_string
  end

  def invalid_xml_identify_datafield(field)
    regex = /[\u0000-\u0008\u000B\u000C\u000E-\u001C\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF]/
    new_field = MARC::DataField.new(field.tag)
    new_field.indicator1 = field.indicator1.gsub(regex, '░')
    new_field.indicator2 = field.indicator2.gsub(regex, '░')
    field.subfields.each do |subfield|
      new_value = invalid_xml_identify_value(subfield.value)
      new_field.append(MARC::Subfield.new(subfield.code, new_value))
    end
    new_field
  end

  def invalid_xml_identify_controlfield(field)
    new_value = invalid_xml_identify_value(field.value)
    MARC::ControlField.new(field.tag, new_value)
  end

  ### Replaces the invalid XML in the Leader and indicators with the special
  ###   character, so as not to invalidate the MARC format
  def invalid_xml_identify(record)
    regex = /[\u0000-\u0008\u000B\u000C\u000E-\u001C\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF]/
    record.leader = record.leader.gsub(regex, '░')
    record.fields.each_with_index do |field, field_index|
      record.fields[field_index] = if field.instance_of?(MARC::DataField)
                                     invalid_xml_identify_datafield(field)
                                   else
                                     invalid_xml_identify_controlfield(field)
                                   end
    end
    record
  end

  ### Finds characters that are discouraged in the XML 1.1 standard
  def invalid_xml_chars?(record)
    regex = /[\u0000-\u0008\u000B\u000C\u000E-\u001C\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF]/
    record.to_s =~ regex ? true : false
  end

  def combining_chars_identify_value(string)
    regex = /([^\p{L}\p{M}]\p{M}+)/
    string.gsub(regex, '░\1░')
  end

  def combining_chars_datafield(field)
    regex = /([^\p{L}\p{M}]\p{M}+)/
    new_field = MARC::DataField.new(field.tag)
    new_field.indicator1 = field.indicator1.gsub(regex, '░')
    new_field.indicator2 = field.indicator2.gsub(regex, '░')
    field.subfields.each do |subfield|
      new_value = combining_chars_identify_value(subfield.value)
      new_field.append(MARC::Subfield.new(subfield.code, new_value))
    end
    new_field
  end

  def combining_chars_controlfield(field)
    new_value = combining_chars_identify_value(field.value)
    MARC::ControlField.new(field.tag, new_value)
  end

  def combining_chars_identify(record)
    regex = /([^\p{L}\p{M}]\p{M}+)/
    record.leader = record.leader.gsub(regex, '░')
    record.fields.each_with_index do |field, field_index|
      record.fields[field_index] = if field.instance_of?(MARC::DataField)
                                     combining_chars_datafield(field)
                                   else
                                     combining_chars_controlfield(field)
                                   end
    end
    record
  end

  def combining_chars_errors?(record)
    pattern = /[^\p{L}\p{M}]\p{M}+/
    record.to_s =~ pattern ? true : false
  end

  def composed_chars_string_error?(string)
    if string =~ /[\u{0653}\u{0654}\u{0655}]/ && !string.unicode_normalized?(:nfc)
      true
    else
      string.codepoints.any? do |codepoint|
        codepoint < 1570 || (7680..10_792).cover?(codepoint) &&
          !codepoint.chr(Encoding::UTF_8).unicode_normalized?(:nfd)
      end
    end
  end

  def composed_chars_errors?(record)
    record.fields.each do |field|
      if field.instance_of?(MARC::DataField)
        return true if field.subfields.any? do |subfield|
          composed_chars_string_error?(subfield.value)
        end
      elsif composed_chars_string_error?(field.value)
        return true
      end
    end
    false
  end

  def composed_chars_normalize_string(string)
    prevalue = string.dup
    prevalue.unicode_normalize!(:nfc) if prevalue =~ /[\u0653\u0654\u0655]/
    prevalue.codepoints.map do |codepoint|
      char = codepoint.chr(Encoding::UTF_8)
      char.unicode_normalize!(:nfd) if codepoint < 1570 || (7_680..10_792).cover?(codepoint)
      char
    end.join
  end

  def composed_chars_normalize_datafield(field)
    new_field = MARC::DataField.new(field.tag)
    new_field.indicator1 = field.indicator1
    new_field.indicator2 = field.indicator2
    field.subfields.each do |subfield|
      new_value = composed_chars_normalize_string(subfield.value)
      new_field.append(MARC::Subfield.new(subfield.code, new_value))
    end
    new_field
  end

  def composed_chars_normalize_controlfield(field)
    new_value = composed_chars_normalize_string(field.value)
    MARC::ControlField.new(field.tag, new_value)
  end

  ### Normalize to the NFC (combined) form of diacritics for characters with
  #     Arabic diacritics; normalize to NFD for characters below U+622 and
  #     between U+1E00 and U+2A28
  def composed_chars_normalize(record)
    record.fields.each_with_index do |field, field_index|
      record.fields[field_index] = if field.instance_of?(MARC::DataField)
                                     composed_chars_normalize_datafield(field)
                                   else
                                     composed_chars_normalize_controlfield(field)
                                   end
    end
    record
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

  def invalid_xml_fix_datafield(field)
    regex = /[\u0000-\u0008\u000B\u000C\u000E-\u001C\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF]/
    new_field = MARC::DataField.new(field.tag)
    new_field.indicator1 = field.indicator1.gsub(regex, ' ')
    new_field.indicator2 = field.indicator2.gsub(regex, ' ')
    field.subfields.each do |subfield|
      new_value = subfield.value.gsub(regex, ' ')
      new_field.append(MARC::Subfield.new(subfield.code, new_value))
    end
    new_field
  end

  def invalid_xml_fix_controlfield(field)
    regex = /[\u0000-\u0008\u000B\u000C\u000E-\u001C\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF]/
    MARC::ControlField.new(field.tag, field.value.gsub(regex, ' '))
  end

  ### Replace invalid XML 1.0 characters with a space
  def invalid_xml_fix(record)
    regex = /[\u0000-\u0008\u000B\u000C\u000E-\u001C\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF]/
    record.leader = record.leader.gsub(regex, ' ')
    record.fields.each_with_index do |field, field_index|
      record.fields[field_index] = if field.instance_of?(MARC::DataField)
                                     invalid_xml_fix_datafield(field)
                                   else
                                     invalid_xml_fix_controlfield(field)
                                   end
    end
    record
  end

  def tab_newline_fix_datafield(field)
    regex = /[\u0009\n\r]/
    new_field = MARC::DataField.new(field.tag)
    new_field.indicator1 = field.indicator1.gsub(regex, ' ')
    new_field.indicator2 = field.indicator2.gsub(regex, ' ')
    field.subfields.each do |subfield|
      new_value = subfield.value.gsub(regex, ' ')
      new_field.append(MARC::Subfield.new(subfield.code, new_value))
    end
    new_field
  end

  def tab_newline_fix_controlfield(field)
    regex = /[\u0009\n\r]/
    MARC::ControlField.new(field.tag, field.value.gsub(regex, ' '))
  end

  ### Replace tab and newline characters with a space
  def tab_newline_fix(record)
    record.leader = record.leader.gsub(/[\u0009\n\r]/, ' ')
    record.fields.each_with_index do |field, field_index|
      record.fields[field_index] = if field.instance_of?(MARC::DataField)
                                     tab_newline_fix_datafield(field)
                                   else
                                     tab_newline_fix_controlfield(field)
                                   end
    end
    record
  end

  ## Can delete fields based on tags alone, or with
  ## optional indicator values provided in arrays
  def field_delete_by_tags(record:, tags:, indicators: {})
    full_indicator_array = [' ']
    full_indicator_array += %w[0 1 2 3 4 5 6 7 8 9]
    indicators[:ind1] ||= full_indicator_array
    indicators[:ind2] ||= full_indicator_array
    record.fields.delete_if do |field|
      tags.include?(field.tag) &&
        indicators[:ind1].include?(field.indicator1) &&
        indicators[:ind2].include?(field.indicator2)
    end
    record
  end

  def recap_fixes(record)
    record = bad_utf8_scrub(record)
    record = field_delete_by_tags(record: record, tags: %w[959 856])
    record = leaderfix(record)
    record = invalid_xml_fix(record)
    record = composed_chars_normalize(record)
    record = tab_newline_fix(record)
    record = extra_space_fix(record)
    empty_subfield_fix(record)
  end

  ### Perform multiple field removals on a record;
  ###   input is an array of hashes with the following attributes:
  ###   - source_field: ruby-marc field (DataField or ControlField)
  ###   - ignore_indicators: optional Boolean to specify whether to ignore
  ###     indicators for this replacement
  ###   - case_sensitive: optional Boolean to specify whether matching
  ###     should be case-sensitive
  def remove_fields(field_array:, record:)
    field_array.each do |field|
      field[:ignore_indicators] = false unless field.key?(:ignore_indicators)
      field[:case_sensitive] = true unless field.key?(:case_sensitive)
      record = remove_field(source_field: field[:source_field],
                            record: record,
                            ignore_indicators: field[:ignore_indicators],
                            case_sensitive: field[:case_sensitive])
    end
    record
  end

  ### Remove field from a record that matches a supplied source field
  ###   which can be either a ControlField or a DataField
  def remove_field(record:, source_field:, ignore_indicators: false, case_sensitive: true)
    start_pos = field_content_start(source_field: source_field,
                                    ignore_indicators: ignore_indicators)
    target_fields = replace_field_targets(record: record,
                                          source_field: source_field,
                                          start_pos: start_pos,
                                          case_sensitive: case_sensitive)
    target_fields.each do |field|
      record.fields.delete(field)
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
      record.fields[record.fields.index(field)] = replacement_field
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

  def sort_0xx_fields(source:, new_record:)
    source.fields('001'..'009').sort_by(&:tag).each do |field|
      new_record.append(field)
    end
    source.fields('010'..'099').each do |field|
      new_record.append(field)
    end
    new_record
  end

  ### Default field sort: sort fixed fields numerically, then sort the rest
  ###   in groups, leaving the order of fields within the group alone
  def field_sort(record)
    new_rec = MARC::Record.new
    new_rec.leader = record.leader
    new_rec = sort_0xx_fields(source: record, new_record: new_rec)
    1.upto(9).each do |tag_start|
      record.fields("#{tag_start}00".."#{tag_start}99").each do |field|
        new_rec.append(field)
      end
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

  ### Duplicate record to preserve original when making modifications;
  ###   must scrub any invalid UTF-8 before duplicating
  def duplicate_record(record)
    raw_marc = ''.dup
    writer = MARC::XMLWriter.new(StringIO.new(raw_marc, 'w'))
    record = bad_utf8_scrub(record)
    writer.write(record)
    writer.close
    reader = MARC::XMLReader.new(StringIO.new(raw_marc, 'r'),
                                 external_encoding: 'UTF-8')
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
    return true unless [' ', 'a', 'b', 'c', 'd', 'f', 'o', 'q', 'r', 's'].include?(form)

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

  def data_field_length(field)
    total_length = field.indicator1.to_s.bytesize
    total_length += field.indicator2.to_s.bytesize
    total_length += 1 # subfield delimiter after indicators
    field.subfields.each do |subfield|
      total_length += subfield.code.bytesize + 1 # include subfield delimiter
      total_length += subfield.value.bytesize
    end
    total_length + 1 # include field terminator
  end

  def control_field_length(field)
    field.value.bytesize + 1 # include field terminator
  end

  ### A field can only have a total bytesize less than 9,999 bytes to be valid binary MARC
  def invalid_field_length?(field)
    if field.instance_of?(MARC::ControlField)
      control_field_length(field) > 9_999
    else
      data_field_length(field) > 9_999
    end
  end

  def directory_length(record)
    (record.fields.size * 12) + 1 # includes field terminator
  end

  def invalid_record_length?(record)
    total_length += record.leader.bytesize if record.leader
    total_length += directory_length(record)
    record.fields.each do |field|
      total_length += if field.instance_of?(MARC::ControlField)
                        control_field_length(field)
                      else
                        data_field_length(field)
                      end
    end
    (total_length + 1) > 99_999 # include record terminator
  end

  ### `schema` is a YAML file loaded as a hash;
  ### schema = YAML.load_file("#{ROOT_DIR}/lib/marc_cleanup/variable_field_schema.yml")
  def validate_marc(record:, schema: RECORD_SCHEMA)
    hash = {}
    hash[:invalid_record_length] = invalid_record_length?(record)
    hash[:multiple_1xx] = multiple_1xx?(record)
    hash[:f130_f240] = f130_f240?(record)
    hash[:multiple_no_f245] = multiple_no_f245?(record)
    hash[:non_repeatable_field_errors] = non_repeatable_field_errors?(record: record, schema: schema)
    hash[:invalid_tags] = record.fields.select do |field|
      field.tag[0] != '9' &&
        !schema.keys.include?(field.tag)
    end.map(&:tag)
    hash[:invalid_fields] = {}
    record.fields.each do |field|
      if field.instance_of?(MARC::ControlField)
        field_num = record.fields(field.tag).index(field) + 1
        if invalid_field_length?(field)
          error = "Field length above 9,999 bytes in instance #{field_num} of #{field.tag}"
          hash[:invalid_fields][field.tag] ||= []
          hash[:invalid_fields][field.tag] << error
        end
      else
        has_link = false
        next unless schema[field.tag]

        field_num = record.fields(field.tag).index(field)
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
          elsif field['6'] =~ /^00[0-9]-[0-9]+/
            error = "Invalid linked fixed field tag in instance #{field_num} of 880"
            hash[:invalid_fields][field.tag] ||= []
            hash[:invalid_fields][field.tag] << error
          else
            tag = field['6'].gsub(/^([0-9]{3})-.*$/, '\1')
            if schema[tag]
              has_link = true
            else
              error = "Invalid linked field tag #{tag} in instance #{field_num} of 880"
              hash[:invalid_fields][field.tag] ||= []
              hash[:invalid_fields][field.tag] << error
            end
          end
        end
        next unless schema[tag]

        unless schema[tag]['ind1'].include?(field.indicator1.to_s)
          error = "Invalid indicator1 value #{field.indicator1} in instance #{field_num}"
          error << " linked to field tag #{tag}" if has_link
          hash[:invalid_fields][field.tag] ||= []
          hash[:invalid_fields][field.tag] << error
        end
        unless schema[tag]['ind2'].include?(field.indicator2.to_s)
          error = "Invalid indicator2 value #{field.indicator2} in instance #{field_num}"
          error << " linked to field tag #{tag}" if has_link
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
            error = "Invalid subfield code #{code} in instance #{field_num}"
            error << " linked to field tag #{tag}" if has_link
            hash[:invalid_fields][field.tag] << error
          elsif schema[tag]['subfields'][code]['repeat'] == false && count > 1
            hash[:invalid_fields][field.tag] ||= []
            error = "Non-repeatable subfield code #{code} repeated in instance #{field_num}"
            error << " linked to field tag #{tag}" if has_link
            hash[:invalid_fields][field.tag] << error
          end
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
    record.leader[18] = 'i' if rda_convention_mismatch(record) == true
    record
  end
end
