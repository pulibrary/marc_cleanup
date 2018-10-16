require_relative './fixed_fields'
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
        subfields_to_delete.unshift(curr_subfield) if subfield.value.empty? || subfield.value.nil?
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

  ## Can delete fields based on tags alone, or with
  ## optional indicator values provided in arrays
  def field_delete(tags, record, indicators = {})
    if indicators.empty?
      record.fields.delete_if { |field| tags.include? field.tag }
    else
      ind_1 = indicators[:ind_1] ? indicators[:ind_1] : nil
      ind_2 = indicators[:ind_2] ? indicators[:ind_2] : nil
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

  def subf_0_fix(record)
    record.fields.each do |field|
      next unless field.class == MARC::DataField && field.tag =~ /^[^9]/ && field['0']
      field_index = record.fields.index(field)
      field.subfields.each do |subfield|
        next unless subfield.code == '0' && subfield.value =~ /^\(uri\)/
        subfield_index = field.subfields.index(subfield)
        record.fields[field_index].subfields[subfield_index].value = subfield.value.gsub(/^\(uri\)(.*)$/, '\1')
      end
    end
    record
  end

  def recap_fixes(record)
    record = bad_utf8_fix(record)
    record = field_delete(['959'], record)
    record = field_delete(['856'], record, { :ind_1 => [' ', '0', '1', '2', '3', '7'] })
    record = leaderfix(record)
    record = extra_space_fix(record)
    record = invalid_xml_fix(record)
    record = composed_chars_normalize(record)
    record = tab_newline_fix(record)
    record = empty_subfield_fix(record)
    record
  end

  def uri_escape(record)
    target_fields = record.fields('856')
    return record if target_fields.empty?
    fixed_record = record
    target_fields.each do |field|
      next unless field['u']
      field_index = fixed_record.fields.index(field)
      field.subfields.each do |subfield|
        next unless subfield.code == 'u'
        subfield_index = field.subfields.index(subfield)
        string = subfield.value
        fixed_string = URI.escape(URI.unescape(string).scrub)
        fixed_record.fields[field_index].subfields[subfield_index].value = fixed_string
      end
    end
    fixed_record
  end

  def fix_008(record)
    target_fields = record.fields('008')
    return record if target_fields.size != 1
    rec_type = record.leader[6..7]
    return record unless rec_type =~ /^[ac-gijkmoprt][abcdims]$/
    fixed_record = record
    field = target_fields.first
    field_index = fixed_record.fields.index(field)
    field_value = field.value
    specific_008 = field_value[18..34]
    date_entered = field_value[0..5]
    date_type = field_value[6]
    date1 = field_value[7..10]
    date2 = field_value[11..14]
    place = field_value[15..17]
    lang = field_value[35..37]
    modified = field_value[38]
    cat_source = field_value[39]
    fixed_008 = field_value
    if cat_source =~ /[abl]/
      fixed_008[39] = ' '
    elsif [' ', 'c', 'd', 'u', '|'].include?(cat_source)
      fixed_008[39] = cat_source
    elsif cat_source == 'o'
      fixed_008[39] = 'd'
    end
    fixed_008[18..34] = case
    when book.include?(rec_type)
      fix_book_008(specific_008)
    when comp_file.include?(rec_type)
      fix_comp_008(specific_008)
    when map.include?(rec_type)
      fix_map_008(specific_008)
    when music.include?(rec_type)
      fix_music_008(specific_008)
    when continuing_resource.include?(rec_type)
      fix_continuing_resource_008(specific_008)
    when visual.include?(rec_type)
      fix_visual_008(specific_008)
    when mixed.include?(rec_type)
      fix_mix_mat_008(specific_008)
    end
    fixed_record.fields[field_index].value = fixed_008
    fixed_record
  end

  def fix_book_008(field)
    fixed_field = ''
    illus = field[0..3]
    audience = field[4]
    item_form = field[5]
    contents = field[6..9]
    gov_pub = field[10]
    conf_pub = field[11]
    festschrift = field[12]
    index_code = field[13]
    lit_form = field[15]
    biog = field[16]
    illus = illus.chars.sort.join('') unless illus == '||||'
    fixed_field << illus
    audience = 'j' if %w[u v].include?(audience)
    fixed_field << audience
    fixed_field << item_form
    unless contents == '||||'
      contents.chars.each_with_index do |char, index|
        case char
        when 'h'
          contents[index] = 'f'
        when '3'
          contents[index] = 'k'
        when 'x'
          contents[index] = 't'
        when '4'
          contents[index] = 'q'
        end
      end
      contents = contents.chars.sort.join('')
    end
    fixed_field << contents
    gov_pub = 'o' if gov_pub == 'n'
    fixed_field << gov_pub
    fixed_field << conf_pub
    fixed_field << festschrift
    fixed_field << index_code
    fixed_field << ' '
    lit_form = '0' if lit_form == ' '
    fixed_field << lit_form
    fixed_field << biog
    fixed_field
  end

  def fix_comp_008(field)
    fixed_field = ''
    audience = field[4]
    item_form = field[5]
    type = field[8]
    gov_pub = field[10]
    fixed_field << '    '
    audience = 'j' if %w[u v].include? audience
    fixed_field << audience
    fixed_field << item_form
    fixed_field << '  '
    fixed_field << type
    fixed_field << ' '
    gov_pub = 'o' if gov_pub == 'n'
    fixed_field << gov_pub
    fixed_field << '      '
    fixed_field
  end

  def fix_map_008(field)
    fixed_field = ''
    relief = field[0..3]
    proj = field[4..5]
    type = field[7]
    gov_pub = field[10]
    item_form = field[11]
    index_code = field[13]
    format = field[15..16]
    unless relief == '||||'
      relief.chars.each_with_index do |char, index|
        relief[index] = 'c' if char == 'h'
      end
      relief = relief.chars.sort.join('')
    end
    fixed_field << relief
    fixed_field << proj
    fixed_field << ' '
    fixed_field << type
    fixed_field << '  '
    gov_pub = 'o' if gov_pub == 'n'
    fixed_field << gov_pub
    fixed_field << item_form
    fixed_field << ' '
    fixed_field << index_code
    fixed_field << ' '
    format = format.chars.sort.join('') unless format == '||'
    fixed_field << format
    fixed_field
  end

  def fix_music_008(field)
    fixed_field = ''
    comp_form = field[0..1]
    music_format = field[2]
    parts = field[3]
    audience = field[4]
    item_form = field[5]
    accompanying = field[6..11]
    lit_text = field[12..13]
    transpose = field[15]
    fixed_field << comp_form
    fixed_field << music_format
    fixed_field << parts
    audience = 'j' if %w[u v].include? audience
    fixed_field << audience
    fixed_field << item_form
    unless accompanying == '||||||'
      accompanying.chars.each_with_index do |char, index|
        accompanying[index] = 'i' if char == 'j'
      end
      accompanying = accompanying.chars.sort.join('')
    end
    fixed_field << accompanying
    unless ['||', '  '].include?(lit_text)
      lit_text = lit_text.chars.sort.join('')
    end
    fixed_field << lit_text
    fixed_field << ' '
    fixed_field << transpose
    fixed_field << ' '
    fixed_field
  end

  def fix_continuing_resource_008(field)
    fixed_field = ''
    freq = field[0]
    reg = field[1]
    cr_type = field[3]
    item_orig_form = field[4]
    item_form = field[5]
    work_nature = field[6]
    contents = field[7..9]
    gov_pub = field[10]
    conf_pub = field[11]
    orig_script = field[15]
    entry = field[16]
    fixed_field << freq
    fixed_field << reg
    fixed_field << ' '
    fixed_field << cr_type
    fixed_field << item_orig_form
    fixed_field << item_form
    fixed_field << work_nature
    unless contents == '|||'
      contents.chars.each_with_index do |char, index|
        next if char =~ cr_contents_codes
        case char
        when '3'
          contents[index] = 'k'
        when 'x'
          contents[index] = 't'
        when '4'
          contents[index] = 'q'
        end
      end
      contents = contents.chars.sort.join('')
    end
    fixed_field << contents
    gov_pub = 'o' if gov_pub == 'n'
    fixed_field << gov_pub
    fixed_field << conf_pub
    fixed_field << '   '
    fixed_field << orig_script
    fixed_field << entry
    fixed_field
  end

  def fix_visual_008(field)
    fixed_field = ''
    runtime = field[0..2]
    audience = field[4]
    gov_pub = field[10]
    item_form = field[11]
    visual_type = field[15]
    technique = field[16]
    fixed_field << runtime
    fixed_field << ' '
    audience = 'j' if %w[u v].include? audience
    fixed_field << audience
    fixed_field << '     '
    gov_pub = 'o' if gov_pub == 'n'
    fixed_field << gov_pub
    fixed_field << item_form
    fixed_field << '   '
    visual_type = 'v' if visual_type == 'e'
    fixed_field << visual_type
    technique = 'n' if technique == ' '
    fixed_field << technique
    fixed_field
  end

  def fix_mix_mat_008(field)
    fixed_field = ''
    item_form = field[5]
    fixed_field << '     '
    fixed_field << item_form
    fixed_field << '           '
    fixed_field
  end
end
