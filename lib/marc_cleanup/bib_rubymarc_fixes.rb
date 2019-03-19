require_relative './fixed_fields'
module MarcCleanup
  def leaderfix(record)
    correct_leader = /[0-9]{5}[acdnp][ac-gijkmoprt][a-dims][\sa][\sa]22[0-9]{5}[1-8uzI-M\s][aciu\s][abcr\s]4500/
    leader = record.leader
    return record if leader =~ correct_leader
    length = leader[0, 5]
    status = leader[5]
    status.gsub!(/[^acdnp]/, 'n')
    record_type = leader[6]
    bib_level = leader[7]
    control = leader[8]
    control.gsub!(/[^a ]/, ' ')
    character_scheme = leader[9]
    indsub = '22'
    base_addr = leader[12, 5]
    enc_level = leader[17]
    enc_level.gsub!(/[^1-8uzIJKLM ]/, 'u')
    cat_form = leader[18]
    cat_form.gsub!(/[^aciu\s]/, 'u')
    multipart = leader[19]
    multipart.gsub!(/[^abcr ]/, ' ')
    final4 = '4500'
    fixed_leader = [length, status, record_type, bib_level, control, character_scheme, indsub, base_addr, enc_level, cat_form, multipart, final4].join
    record.leader = fixed_leader
    record
  end

  def extra_space_gsub(string)
    string.gsub!(/([[:blank:]]){2,}/, '\1')
    string.gsub!(/^(.*)[[:blank:]]+$/, '\1')
    string.gsub(/^[[:blank:]]+(.*)$/, '\1')
  end

  def extra_space_fix(record)
    record.fields.each do |field|
      next unless field.class == MARC::DataField && field.tag != '010'
      field_index = record.fields.index(field)
      curr_subfield = -1
      case field.tag
      when /^[1-469]..|0[2-9].|01[1-9]|7[0-5].|5[0-24-9].|53[0-24-9]/
        field.subfields.each do |subfield|
          curr_subfield += 1
          next if subfield.value.nil?
          record.fields[field_index].subfields[curr_subfield].value = extra_space_gsub(subfield.value)
        end
      when '533'
        field.subfields.each do |subfield|
          curr_subfield += 1
          next if subfield.code == '7' || subfield.value.nil?
          record.fields[field_index].subfields[curr_subfield].value = extra_space_gsub(subfield.value)
        end
      when /^7[6-8]./
        field.subfields.each do |subfield|
          curr_subfield += 1
          next if subfield.code =~ /[^a-v3-8]/ || subfield.value.nil?
          record.fields[field_index].subfields[curr_subfield].value = extra_space_gsub(subfield.value)
        end
      when /^8../
        field.subfields.each do |subfield|
          curr_subfield += 1
          next if %w[w 7].include? subfield.code || subfield.value.nil?
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
          char = c.chr(Encoding::UTF_8)
          char.unicode_normalize!(:nfd) if c < 1570 || (7_680..10_792).cover?(c)
          fixed_subfield << char
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

  def empty_indicator_fix(record)
    record.fields.each do |field|
      next unless field.class == MARC::DataField
      field.indicator1 = ' ' if field.indicator1.nil?
      field.indicator2 = ' ' if field.indicator2.nil?
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
    record = field_delete(['856'], record)
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

  def fix_040b(record)
    f040 = record.fields('040')
    return record unless f040.size == 1
    f040 = f040.first
    field_index = record.fields.index(f040)
    b040 = f040.subfields.select { |subfield| subfield.code == 'b' }
    return record unless b040.empty?
    subf_codes = f040.subfields.map { |subfield| subfield.code }
    subf_index = if f040['a']
                   (subf_codes.index { |i| i == 'a' }) + 1
                 else
                   0
                 end
    subf_b = MARC::Subfield.new('b', 'eng')
    record.fields[field_index].subfields.insert(subf_index, subf_b)
    record
  end

  def fix_007(record)
    target_fields = record.fields('007')
    return record if target_fields.empty?
    target_fields.each do |field|
      field_index = record.fields.index(field)
      field_value = field.value
      rec_type = field_value[0]
      next unless %w[a c d f g h k m o q r s t v z].include? rec_type
      fixed_007 = rec_type
      specific_007 = field_value[1..-1]
      next unless specific_007
      case rec_type
      when 'a'
        fixed_007 << fix_map_007(specific_007)
      when 'c'
        fixed_007 << fix_electronic_007(specific_007)
      when 'd'
        fixed_007 << fix_globe_007(specific_007)
      when 'f'
        fixed_007 << fix_tactile_007(specific_007)
      when 'g'
        fixed_007 << fix_proj_007(specific_007)
      when 'h'
        fixed_007 << fix_microform_007(specific_007)
      when 'k'
        fixed_007 << fix_nonproj_007(specific_007)
      when 'm'
        fixed_007 << fix_motion_pic_007(specific_007)
      when 'o'
        fixed_007 << fix_kit_007(specific_007)
      when 'q'
        fixed_007 << fix_notated_mus_007(specific_007)
      when 'r'
        fixed_007 << fix_remote_007(specific_007)
      when 's'
        fixed_007 << fix_sound_rec_007(specific_007)
      when 't'
        fixed_007 << fix_text_007(specific_007)
      when 'v'
        fixed_007 << fix_video_007(specific_007)
      when 'z'
        fixed_007 << fix_unspec_007(specific_007)
      end
      record.fields[field_index].value = fixed_007
    end
    record
  end

  def fix_map_007(specific_007)
    return specific_007 unless specific_007.length == 7
    fixed_field = ''
    mat_designation = specific_007[0]
    color = specific_007[2]
    color.gsub!('b', 'c')
    medium = specific_007[3]
    medium.gsub!(/[^a-gijlnp-z\|]/, 'u')
    repro_type = specific_007[4]
    repro_type.gsub!(/[^fnuz\|]/, 'u')
    prod_details = specific_007[5]
    prod_details.gsub!(/[^abcduz\|]/, 'u')
    aspect = specific_007[6]
    aspect.gsub!('u', '|')
    fixed_field << mat_designation
    fixed_field << ' '
    fixed_field << color
    fixed_field << medium
    fixed_field << repro_type
    fixed_field << prod_details
    fixed_field << aspect
    fixed_field
  end

  def fix_electronic_007(specific_007)
    return specific_007 unless specific_007.length > 4
    fixed_field = ''
    mat_designation = specific_007[0]
    mat_designation.gsub!(/[^a-fhjkmorsuz|]/, 'u')
    color = specific_007[2]
    color.gsub!(/[^abcghmnuz|]/, 'u')
    dimensions = specific_007[3]
    dimensions.gsub!(/[^aegijnouvz|]/, 'u')
    sound = specific_007[4]
    sound.gsub!(/[^ au|]/, 'u')
    fixed_field << mat_designation
    fixed_field << ' '
    fixed_field << color
    fixed_field << dimensions
    fixed_field << sound
    return fixed_field if specific_007.length == 5
    bit_depth = specific_007[5..7]
    unless %w[mmm nnn --- |||].include? bit_depth
      bit_depth =~ /^[0-9]{3}$/ ? bit_depth : '---'
    end
    fixed_field << bit_depth
    formats = specific_007[8]
    return fixed_field unless formats
    formats.gsub!(/[^amu|]/, 'u')
    fixed_field << formats
    quality = specific_007[9]
    return fixed_field unless quality
    quality.gsub!(/[^anpu|]/, 'u')
    fixed_field << quality
    source = specific_007[10]
    return fixed_field unless source
    source.gsub!(/[^abcdmnu|]/, 'u')
    fixed_field << source
    compression = specific_007[11]
    return fixed_field unless compression
    compression.gsub!(/[^abdmu|]/, 'u')
    fixed_field << compression
    reformatting = specific_007[12]
    return fixed_field unless reformatting
    reformatting.gsub!(/[^anpru|]/, 'u')
    fixed_field << reformatting
    fixed_field
  end

  def fix_globe_007(specific_007)
    return specific_007 unless specific_007.length == 7
    fixed_field = ''
    mat_designation = specific_007[0]
    mat_designation.gsub!(/[^abcdeuz|]/, 'u')
    color = specific_007[2]
    color.gsub!('b', 'c')
    medium = specific_007[3]
    medium.gsub!(/[^a-gilnpuvwz|]/, 'u')
    repro_type = specific_007[4]
    repro_type.gsub!(/[^fnuz|]/, 'u')
    fixed_field << mat_designation
    fixed_field << ' '
    fixed_field << color
    fixed_field << medium
    fixed_field << repro_type
    fixed_field
  end

  def fix_tactile_007(specific_007)
    return specific_007 unless specific_007.length == 9
    fixed_field = ''
    mat_designation = specific_007[0]
    mat_designation.gsub!(/[^abcduz|]/, 'u')
    writing = specific_007[2..3]
    unless writing == '||'
      writing_chars = relief.chars.select { |c| c =~ /[a-emnuz]/ }.sort.join('')
      writing = writing_chars.ljust(2)
    end
    contraction = specific_007[4]
    contraction.gsub!(/[^abmnuz|]/, 'u')
    music = specific_007[5..7]
    unless music == '|||'
      music_chars = relief.chars.select { |c| c =~ /[a-lnuz]/ }.sort.join('')
      music = music_chars.ljust(3)
    end
    special = specific_007[8]
    special.gsub!(/[^abnuz|]/, 'u')
    fixed_field << mat_designation
    fixed_field << ' '
    fixed_field << writing
    fixed_field << contraction
    fixed_field << music
    fixed_field << special
    fixed_field
  end

  def fix_proj_007(specific_007)
    return specific_007 unless specific_007.length == 8
    fixed_field = ''
    mat_designation = specific_007[0]
    mat_designation.gsub!(/[^cdfostuz|]/, 'u')
    color = specific_007[2]
    color.gsub!(/[^abchmnuz|]/, 'u')
    base = specific_007[3]
    base.gsub!(/[^dejkmouz|]/, 'u')
    sound_on_medium = specific_007[4]
    sound_on_medium.gsub!(/[^ abu|]/, 'u')
    sound_medium = specific_007[5]
    sound_medium.gsub!(/[^ a-iuz|]/, 'u')
    dimensions = specific_007[6]
    dimensions.gsub!(/[^a-gjkst-z|]/, 'u')
    support = specific_007[7]
    support.gsub!(/[^ cdehjkmuz|]/, 'u')
    fixed_field << mat_designation
    fixed_field << ' '
    fixed_field << color
    fixed_field << base
    fixed_field << sound_on_medium
    fixed_field << sound_medium
    fixed_field << dimensions
    fixed_field << support
    fixed_field
  end

  def fix_microform_007(specific_007)
    return specific_007 unless specific_007.length == 12
    fixed_field = ''
    mat_designation = specific_007[0]
    mat_designation.gsub!(/[^a-hjuz|]/, 'u')
    aspect = specific_007[2]
    aspect.gsub!(/[^abmu|]/, 'u')
    dimensions = specific_007[3]
    dimensions.gsub!(/[^adfghlmopuz|]/, 'u')
    reduction_range = specific_007[4]
    reduction_range.gsub!(/[^a-euv|]/, 'u')
    reduction_ratio = specific_007[5..7]
    unless %w[--- |||].include? reduction_ratio
      reduction_ratio =~ /^[0-9]/ ? reduction_ratio : '---'
      reduction_nums = reduction_ratio.chars.select { |c| c =~ /[0-9]/ }.join('')
      reduction_ratio = reduction_nums.ljust(3, '-')
    end
    color = specific_007[8]
    color.gsub!(/[^bcmuz|]/, 'u')
    emulsion = specific_007[9]
    emulsion.gsub!(/[^abcmnuz|]/, 'u')
    generation = specific_007[10]
    generation.gsub!(/[^abcmu|]/, 'u')
    base = specific_007[11]
    base.gsub!(/[^abcdimnprtuz|]/, 'u')
    fixed_field << mat_designation
    fixed_field << ' '
    fixed_field << aspect
    fixed_field << dimensions
    fixed_field << reduction_range
    fixed_field << reduction_ratio
    fixed_field << color
    fixed_field << emulsion
    fixed_field << generation
    fixed_field << base
    fixed_field
  end

  def fix_nonproj_007(specific_007)
    return specific_007 unless specific_007.length == 5
    fixed_field = ''
    mat_designation = specific_007[0]
    mat_designation.gsub!(/[^ac-ln-suvz|]/, 'u')
    color = specific_007[2]
    color.gsub!(/[^abchmuz|]/, 'u')
    primary_support = specific_007[3]
    primary_support.gsub!(/[^a-il-wz|]/, 'u')
    secondary_support = specific_007[4]
    secondary_support.gsub!(/[^ a-il-wz|]/, 'u')
    fixed_field << mat_designation
    fixed_field << ' '
    fixed_field << color
    fixed_field << primary_support
    fixed_field << secondary_support
    fixed_field
  end

  def fix_motion_pic_007(specific_007)
    return specific_007 unless specific_007.length > 6
    fixed_field = ''
    mat_designation = specific_007[0]
    mat_designation.gsub!(/[^cdforuz|]/, 'u')
    color = specific_007[2]
    color.gsub!(/[^bchmnuz|]/, 'u')
    presentation = specific_007[3]
    presentation.gsub!(/[^a-fuz|]/, 'u')
    sound_on_medium = specific_007[4]
    sound_on_medium.gsub!(/[^ abu|]/, 'u')
    sound_medium = specific_007[5]
    sound_medium.gsub!(/[^ a-iuz|]/, 'u')
    dimensions = specific_007[6]
    dimensions.gsub!(/[^a-guz|]/, 'u')
    fixed_field << mat_designation
    fixed_field << ' '
    fixed_field << color
    fixed_field << presentation
    fixed_field << sound_on_medium
    fixed_field << sound_medium
    fixed_field << dimensions
    return fixed_field if specific_007.length == 7
    channels = specific_007[7]
    channels.gsub!(/[^kmnqsuz|]/, 'u')
    fixed_field << channels
    elements = specific_007[8]
    return fixed_field unless elements
    elements.gsub!('h', 'z')
    elements.gsub!(/[^abcdefgnz|]/, '|')
    fixed_field << elements
    aspect = specific_007[9]
    return fixed_field unless aspect
    aspect.gsub!(/[^abnuz|]/, 'u')
    fixed_field << aspect
    generation = specific_007[10]
    return fixed_field unless generation
    generation.gsub!(/[^deoruz|]/, 'u')
    fixed_field << generation
    base = specific_007[11]
    return fixed_field unless base
    base.gsub!(/[^acdimnprtuz|]/, 'u')
    fixed_field << base
    refined = specific_007[12]
    return fixed_field unless refined
    refined.gsub!(/[^a-np-vz|]/, 'u')
    fixed_field << refined
    stock = specific_007[13]
    return fixed_field unless stock
    stock.gsub!(/[^abcdnuz|]/, 'u')
    fixed_field << stock
    deterioration = specific_007[14]
    return fixed_field unless deterioration
    deterioration.gsub!(/[^abcdefghklm|]/, '|')
    fixed_field << deterioration
    completeness = specific_007[15]
    return fixed_field unless completeness
    completeness.gsub!(/[^cinu|]/, 'u')
    fixed_field << completeness
    return fixed_field if specific_007.length == 16
    inspect_date = specific_007[16-21]
    inspect_date.gsub!(/[^0-9\-]/, '-')
    fixed_field << inspect_date
    fixed_field
  end

  def fix_kit_007(specific_007)
    mat_designation = specific_007[0]
    mat_designation.gsub(/[^u|]/, 'u')
  end

  def fix_notated_mus_007(specific_007)
    mat_designation = specific_007[0]
    mat_designation.gsub(/[^u|]/, 'u')
  end

  def fix_remote_007(specific_007)
    return specific_007 unless specific_007.length == 10
    fixed_field = ''
    mat_designation = specific_007[0]
    mat_designation.gsub!(/[^u|]/, 'u')
    altitude = specific_007[2]
    altitude.gsub!(/[^abcnuz|]/, 'u')
    attitude = specific_007[3]
    attitude.gsub!(/[^abcnuz|]/, 'u')
    clouds = specific_007[4]
    clouds.gsub!(/[^0-9nu|]/, 'u')
    construction = specific_007[5]
    construction.gsub!(/[^a-inuz|]/, 'u')
    use = specific_007[6]
    use.gsub!(/[^abcmnuz|]/, 'u')
    sensor = specific_007[7]
    sensor.gsub!(/[^abuz|]/, 'u')
    data_type = specific_007[8..9]
    data_type = 'uu' unless remote_data_types.include? data_type
    fixed_field << mat_designation
    fixed_field << ' '
    fixed_field << altitude
    fixed_field << attitude
    fixed_field << clouds
    fixed_field << construction
    fixed_field << use
    fixed_field << sensor
    fixed_field << data_type
    fixed_field
  end

  def fix_sound_rec_007(specific_007)
    return specific_007 unless specific_007.length == 13
    fixed_field = ''
    mat_designation = specific_007[0]
    mat_designation = case mat_designation
                      when 'c'
                        'e'
                      when 'f'
                        'i'
                      else
                        mat_designation
                      end
    mat_designation.gsub!(/[^degiq-uwz|]/, 'u')
    speed = specific_007[2]
    speed.gsub!(/[^a-fhik-pruz|]/, 'u')
    channels = specific_007[3]
    channels.gsub!(/[^mqsuz|]/, 'u')
    groove = specific_007[4]
    groove.gsub!(/[^mnsuz|]/, 'u')
    dimensions = specific_007[5]
    dimensions.gsub!(/[^abcdefgjnosuz|]/, 'u')
    width = specific_007[6]
    width = case width
            when 'a'
              'm'
            when 'b'
              'o'
            when 'c'
              'p'
            else
              width
            end
    width.gsub!(/[^l-puz|]/, 'u')
    configuration = specific_007[7]
    configuration.gsub!(/[^abcdefnuz|]/, 'u')
    disc_kind = specific_007[8]
    disc_kind.gsub!(/[^abdimnrstuz|]/, 'u')
    material = specific_007[9]
    material.gsub!(/[^abcgilmnprswuz|]/, 'u')
    cutting = specific_007[10]
    cutting.gsub!(/[^hlnu|]/, 'u')
    playback = specific_007[11]
    playback.gsub!(/[^abcdefghnuz|]/, 'u')
    storage = specific_007[12]
    storage.gsub!(/[^abdeuz|]/, 'u')
    fixed_field << mat_designation
    fixed_field << ' '
    fixed_field << speed
    fixed_field << channels
    fixed_field << groove
    fixed_field << dimensions
    fixed_field << width
    fixed_field << configuration
    fixed_field << disc_kind
    fixed_field << material
    fixed_field << cutting
    fixed_field << playback
    fixed_field << storage
    fixed_field
  end

  def fix_text_007(specific_007)
    mat_designation = specific_007[0]
    mat_designation.gsub(/[^abcduz|]/, 'u')
  end

  def fix_video_007(specific_007)
    return specific_007 unless specific_007.length == 8
    fixed_field = ''
    mat_designation = specific_007[0]
    mat_designation.gsub!(/[^cdfruz|]/, 'u')
    color = specific_007[2]
    color.gsub!(/[^abcmnuz|]/, 'u')
    format = specific_007[3]
    format.gsub!(/[^a-kmopqsuvz|]/, 'u')
    sound_on_medium = specific_007[4]
    sound_on_medium.gsub!(/[^ abu|]/, 'u')
    sound_medium = specific_007[5]
    sound_medium.gsub!(/[^ abcdefghiuz|]/, 'u')
    dimensions = specific_007[6]
    dimensions.gsub!(/[^amopqruz|]/, 'u')
    channels = specific_007[7]
    channels.gsub!(/[^kmnqsuz|]/, 'u')
    fixed_field << mat_designation
    fixed_field << ' '
    fixed_field << color
    fixed_field << format
    fixed_field << sound_on_medium
    fixed_field << sound_medium
    fixed_field << dimensions
    fixed_field << channels
    fixed_field
  end

  def fix_unspec_007(specific_007)
    mat_designation = specific_007[0]
    mat_designation.gsub(/[^muz|]/, 'u')
  end

  def contents_chars
    %w[a b c d e f g h i k l m n o p q r s t u v w y z 5 6]
  end

  def fix_contents_chars(contents)
    return contents if contents =~ /[\|]+$/
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
      contents_values = contents.chars.select { |c| contents_chars.include? c }.sort.join('')
      contents_values.ljust(contents.size)
    end

  def fix_006(record)
    target_fields = record.fields('006')
    return record if target_fields.empty?
    target_fields.each do |field|
      next if field.value.size != 18
      rec_type = field.value[0]
      next unless rec_type =~ /[ac-gijkmoprst]/
      specific_006 = field.value[1..-1]
      field.value[1..-1] = case rec_type
                           when 'a', 't'
                             fix_book_008(specific_006)
                           when 'c', 'd', 'i', 'j'
                             fix_music_008(specific_006)
                           when 'e', 'f'
                             fix_map_008(specific_006)
                           when 'g', 'k', 'o', 'r'
                             fix_visual_008(specific_006)
                           when 'm'
                             fix_comp_008(specific_006)
                           when 'p'
                             fix_mix_mat_008(specific_006)
                           when 's'
                             fix_continuing_resource_008(specific_006)
                           end
    end
    record
  end

  def fix_008(record)
    target_fields = record.fields('008')
    return record if target_fields.size != 1
    rec_type = record.leader[6..7]
    return record unless rec_type =~ /^[ac-gijkmoprt][abcdims]$/
    fixed_record = record
    field = target_fields.first
    return record if field.value.size != 40
    field_index = fixed_record.fields.index(field)
    field_value = field.value
    specific_008 = field_value[18..34]
    modified = field_value[38]
    cat_source = field_value[39]
    fixed_008 = field_value
    fixed_008[38] = '|' if modified == 'u'
    if cat_source =~ /[abl]/
      fixed_008[39] = ' '
    elsif [' ', 'c', 'd', 'u', '|'].include? cat_source
      fixed_008[39] = cat_source
    elsif cat_source == 'o'
      fixed_008[39] = 'd'
    end
    fixed_008[18..34] =
      if book.include? rec_type
        fix_book_008(specific_008)
      elsif comp_file.include? rec_type
        fix_comp_008(specific_008)
      elsif map.include? rec_type
        fix_map_008(specific_008)
      elsif music.include? rec_type
        fix_music_008(specific_008)
      elsif continuing_resource.include? rec_type
        fix_continuing_resource_008(specific_008)
      elsif visual.include? rec_type
        fix_visual_008(specific_008)
      elsif mixed.include? rec_type
        fix_mix_mat_008(specific_008)
      else
        specific_008
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
    unless illus == '||||'
      illus_chars = illus.chars.select { |c| %w[a b c d e f g h i j k l m o p].include? c }.sort.join('')
      illus = illus_chars.ljust(4)
    end
    fixed_field << illus
    audience.gsub!(/[uv]/, 'j')
    fixed_field << audience
    fixed_field << item_form
    contents = fix_contents_chars(contents)
    fixed_field << contents
    gov_pub.gsub!('n', 'o')
    fixed_field << gov_pub
    fixed_field << conf_pub
    fixed_field << festschrift
    fixed_field << index_code
    fixed_field << ' '
    lit_form.gsub!(' ', '0')
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
    audience.gsub!(/[uv]/, 'j')
    fixed_field << audience
    fixed_field << item_form
    fixed_field << '  '
    fixed_field << type
    fixed_field << ' '
    gov_pub.gsub!('n', 'o')
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
      relief.gsub!('h', 'c')
      relief_chars = relief.chars.select { |c| %w[a b c d e f g i j k m z ].include? c }.sort.join('')
      relief = relief_chars.ljust(4)
    end
    fixed_field << relief
    fixed_field << proj
    fixed_field << ' '
    fixed_field << type
    fixed_field << '  '
    gov_pub.gsub!('n', 'o')
    fixed_field << gov_pub
    fixed_field << item_form
    fixed_field << ' '
    fixed_field << index_code
    fixed_field << ' '
    unless format == '||'
      format_chars = format.chars.select { |c| %w[e j k l n o p r z].include? c }.sort.join('')
      format = format_chars.ljust(2)
    end
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
    audience.gsub!(/[uv]/, 'j')
    fixed_field << audience
    fixed_field << item_form
    unless accompanying == '||||||'
      accompanying.gsub!('j', 'i')
      accompanying_chars = accompanying.chars.select { |c| %w[a b c d e f g h i k r s z].include? c }.sort.join('')
      accompanying = accompanying_chars.ljust(6)
    end
    fixed_field << accompanying
    unless ['||', '  '].include? lit_text
      lit_text_chars = lit_text.chars.select { |c| %w[a b c d e f g h i j k l m n o p r s t z].include? c }.sort.join('')
      lit_text = lit_text_chars.ljust(2)
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
    contents = fix_contents_chars(contents)
    fixed_field << contents
    gov_pub.gsub!('n', 'o')
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
    audience.gsub!(/[uv]/, 'j')
    fixed_field << audience
    fixed_field << '     '
    gov_pub.gsub!('n', 'o')
    fixed_field << gov_pub
    fixed_field << item_form
    fixed_field << '   '
    visual_type.gsub!('e', 'v')
    fixed_field << visual_type
    technique.gsub!(' ', 'n')
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
