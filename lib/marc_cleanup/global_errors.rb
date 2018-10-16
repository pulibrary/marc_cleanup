module MarcCleanup
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

  def repeatable_field_errors?(record)
    field_count = record.fields.group_by(&:tag).map { |key, value| { tag: key, count: value.size } }
    nr_fields = field_count.select { |item| non_repeatable_fields.include?(item[:tag]) && item[:count] > 1 }
    !nr_fields.empty?
  end

  def invalid_tag?(record)
    record.tags.find { |x| x =~ /[^0-9]/ } ? true : false
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
end
