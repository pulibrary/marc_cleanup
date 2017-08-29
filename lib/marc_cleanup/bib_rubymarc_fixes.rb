module MarcCleanup
  def leaderfix(record)
    correct_leader = /[0-9]{5}[acdnp][ac-gijkmoprt][a-dims][\sa][\sa]22[0-9]{5}[1-8uzI-M\s][aciu\s][abcr\s]4500/
    leader = record.leader
    return record if leader =~ correct_leader
    length = leader[0, 5]
    status = leader[5] =~ /[^acdnp]/ ? 'n' : leader[5]
    record_type = leader[6]
    bib_level = leader[7]
    control = leader[8] =~ /[^a\s]/ ? ' ' : leader[8]
    character_scheme = leader[9]
    indsub = '22'
    base_addr = leader[12, 5]
    enc_level = leader[17] =~ /[^1-8uzIJKLM ]/ ? 'u' : leader[17]
    cat_form = leader[18] =~ /[^aciu\s]/ ? 'u' : leader[18]
    multipart = leader[19] =~ /[^abcr ]/ ? ' ' : leader[19]
    final4 = '4500'
    fixed_leader = [length, status, record_type, bib_level, control, character_scheme, indsub, base_addr, enc_level, cat_form, multipart, final4].join
    record.leader = fixed_leader
    record
  end

  def extra_space_gsub(string)
    string.gsub(/([[:blank:]]){2,}/, '\1').gsub(/^(.*)[[:blank:]]+$/, '\1').gsub(/^[[:blank:]]+(.*)$/, '\1')
  end

  def extra_space_fix(record)
    record.fields.each do |field|
      next unless field.class == MARC::DataField && field.tag != '010'
      field_index = record.fields.index(field)
      curr_subfield = -1
      if field.tag =~ /[1-469]..|0[2-9].|01[1-9]|7[0-5].|5[0-24-9].|53[0-24-9]/
        field.subfields.each do |subfield|
          curr_subfield += 1
          next if subfield.value.nil?
          record.fields[field_index].subfields[curr_subfield].value = extra_space_gsub(subfield.value)
        end
      elsif field.tag == '533'
        field.subfields.each do |subfield|
          curr_subfield += 1
          next if subfield.code == '7' || subfield.value.nil?
          record.fields[field_index].subfields[curr_subfield].value = extra_space_gsub(subfield.value)
        end
      elsif field.tag =~ /7[6-8]./
        field.subfields.each do |subfield|
          curr_subfield += 1
          next if subfield.code =~ /[^a-v3-8]/ || subfield.value.nil?
          record.fields[field_index].subfields[curr_subfield].value = extra_space_gsub(subfield.value)
        end
      elsif field.tag =~ /8../
        field.subfields.each do |subfield|
          curr_subfield += 1
          next if subfield.code =~ /[w7]/ || subfield.value.nil?
          record.fields[field_index].subfields[curr_subfield].value = extra_space_gsub(subfield.value)
        end
      end
    end
    record
  end

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

  def composed_chars_normalize(record)
    record.fields.each do |field|
      next unless field.class == MARC::DataField
      field_index = record.fields.index(field)
      curr_subfield = 0
      field.subfields.each do |subfield|
        fixed_subfield = ''
        prevalue = subfield.value
        if prevalue =~ /^.*[\u0653\u0654\u0655].*$/
          prevalue = prevalue.unicode_normalize(:nfc)
        end
        prevalue.each_codepoint do |c|
          if c < 1570 || (7_680..10_792).cover?(c)
            fixed_subfield << c.chr(Encoding::UTF_8).unicode_normalize(:nfd)
          else
            fixed_subfield << c.chr(Encoding::UTF_8)
          end
        end
        record.fields[field_index].subfields[curr_subfield].value = fixed_subfield
        curr_subfield += 1
      end
    end
    record
  end

  def tab_newline_fix(record)
    regex = /[\x09\n\r]/
    record.leader.gsub!(regex, ' ')
    record.fields.each do |field|
      field_index = record.fields.index(field)
      if field.class == MARC::DataField
        curr_subfield = 0
        final_subfield = field.subfields.length
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

  def empty_subfield_fix(record)
    fields_to_delete = []
    curr_field = -1
    record.fields.each do |field|
      curr_field += 1
      next unless field.class == MARC::DataField
      curr_subfield = 0
      subfields_to_delete = []
      field.subfields.each do |subfield|
        subfields_to_delete.unshift(curr_subfield) if subfield.value.nil? == ''
        curr_subfield += 1
      end
      subfields_to_delete.each do |i|
        record.fields[curr_field].subfields.delete_at(i)
      end
      fields_to_delete.unshift(curr_field) if record.fields[curr_field].subfields.empty?
    end
    unless fields_to_delete.empty?
      fields_to_delete.each do |i|
        record.fields.delete_at(i)
      end
    end
    record
  end

  def field_delete(tags, record)
    curr_field = -1
    fields_to_delete = []
    record.fields.each do |field|
      curr_field += 1
      next unless tags.include? field.tag
      fields_to_delete.unshift(curr_field)
    end
    unless fields_to_delete.empty?
      fields_to_delete.each do |i|
        record.fields.delete_at(i)
      end
    end
    record
  end

  def recap_fixes(record)
    record = bad_utf8_fix(record)
    record = field_delete(['856', '959'], record)
    record = leaderfix(record)
    record = extra_space_fix(record)
    record = invalid_xml_fix(record)
    record = composed_chars_normalize(record)
    record = tab_newline_fix(record)
    record = empty_subfield_fix(record)
    record
  end
end
