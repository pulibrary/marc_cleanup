# frozen_string_literal: true

module MarcCleanup
  def no_f001?(record)
    record['001'].nil?
  end

  def fixed_field_char_errors?(record)
    fields = record.fields('001'..'009').map(&:value)
    bad_fields = fields.reject { |value| value.bytesize == value.chars.size }
    bad_fields += fields.select { |value| value =~ /[^a-z0-9 |.A-Z-]/ }
    !bad_fields.empty?
  end

  def multiple_no_f008?(record)
    record.fields('008').size != 1
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

  def projection_codes
    YAML.load_file("#{ROOT_DIR}/yaml/fixed_fields/projection_codes.yml")
  end

  def map_type_codes
    /[a-guz|]/
  end

  def map_special_format_codes
    /[ ejklnoprz]+/
  end

  def composition_codes
    YAML.load_file("#{ROOT_DIR}/yaml/fixed_fields/composition_codes.yml")
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

  def global_f008_error?(field)
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
    return true unless date1 == '||||' || date1 == '    ' || date1 =~ /^[0-9u]{4}$/

    case date_type
    when 'e'
      return true unless date2 =~ /^[0-9]+\s*$/
    else
      return true unless date2 == '||||' || date2 == '    ' || date2 =~ /^[0-9u]{4}$/
    end
    return true unless place == '|||' || PLACE_CODES.include?(place)
    return true unless lang == '|||'  || LANGUAGE_CODES.include?(lang)
    return true unless [' ', 'd', 'o', 'r', 's', 'x', '|'].include?(modified)
    return true unless [' ', 'c', 'd', 'u', '|'].include?(cat_source)

    false
  end

  def book_f008_error?(field)
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

  def comp_f008_error?(field)
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
    return true unless [' ', '|'].include?(undef3)
    return true unless gov_pub =~ gov_pub_codes
    return true unless ['||||||', '      '].include?(undef4)

    false
  end

  def map_f008_error?(field)
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
    return true unless projection_codes.include?(proj)
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

  def music_f008_error?(field)
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

  def continuing_resource_f008_error?(field)
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

  def visual_f008_error?(field)
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

    false
  end

  def mix_mat_f008_error?(field)
    undef1 = field[0..4]
    item_form = field[5]
    undef2 = field[6..16]
    return true unless ['     ', '|||||'].include?(undef1)
    return true unless item_form =~ item_form_codes
    return true unless ['           ', '|||||||||||'].include?(undef2)

    false
  end

  def record_type(leader_portion)
    RECORD_TYPES.find { |_type, values| values.include?(leader_portion) }[0]
  end

  def bad_f005?(record)
    field = record['005']
    return false unless field

    field.value =~ /^[0-9]{14}\.[0-9]$/ ? false : true
  end

  # Uses same methods as the specific 008 methods
  def bad_f006?(record)
    fields = record.fields('006')
    return false if fields.empty?

    fields.each do |field|
      return true if field.value.length != 18

      rec_type = field.value[0]
      specific_f006 = field.value[1..]
      case rec_type
      when 'a', 't'
        return true if book_f008_error?(specific_f006)
      when 'm'
        return true if comp_f008_error?(specific_f006)
      when 'e', 'f'
        return true if map_f008_error?(specific_f006)
      when 'c', 'd', 'i', 'j'
        return true if music_f008_error?(specific_f006)
      when 's'
        return true if continuing_resource_f008_error?(specific_f006)
      when 'g', 'k', 'o', 'r'
        return true if visual_f008_error?(specific_f006)
      when 'p'
        return true if mix_mat_f008_error?(specific_f006)
      end
    end
    false
  end

  def map_f007(field)
    return true unless field.length == 7
    return true unless %w[d g j k q r s u y z |].include?(field[0])
    return true unless field[1] == ' '
    return true unless %w[a c |].include?(field[2])
    return true unless %w[a b c d e f g i j l n p q r s t u v w x y z |].include?(field[3])
    return true unless %w[f n u z |].include?(field[4])
    return true unless %w[a b c d u z |].include?(field[5])
    return true unless %w[a b m n |].include?(field[6])

    false
  end

  def elec_f007(field)
    return true unless field.length == 13
    return true unless %w[a b c d e f h j k m o r s u z |].include?(field[0])
    return true unless field[1] == ' '
    return true unless %w[a b c g m n u z |].include?(field[2])
    return true unless %w[a e g i j n o u v z |].include?(field[3])
    return true unless [' ', 'a', 'u', '|'].include?(field[4])
    return true unless %w[mmm nnn --- |||].include?(field[5..7]) || field[5..7] =~ /^[0-9]{3}$/
    return true unless %w[a m u |].include?(field[8])
    return true unless %w[a n p u |].include?(field[9])
    return true unless %w[a b c d m n u |].include?(field[10])
    return true unless %w[a b d m u |].include?(field[11])
    return true unless %w[a n p r u |].include?(field[12])

    false
  end

  def globe_f007(field)
    return true unless field.length == 5
    return true unless %w[a b c e u z |].include?(field[0])
    return true unless field[1] == ' '
    return true unless %w[a c |].include?(field[2])
    return true unless %w[a b c d e f g i l n p u v w z |].include?(field[3])
    return true unless %w[f n u z |].include?(field[4])

    false
  end

  def tactile_f007(field)
    return true unless field.length == 9
    return true unless %w[a b c d u z |].include?(field[0])
    return true unless field[1] == ' '
    return true unless field[2..3] == '||' || field[2..3] =~ /^[abcdemnuz ]{2}$/
    return true unless %w[a b m n u z |].include?(field[4])
    return true unless field[5..7] == '||' || field[5..7] =~ /^[abcdefghijklnuz ]{3}$/
    return true unless %w[a b n u z |].include?(field[8])

    false
  end

  def proj_graphic_f007(field)
    return true unless field.length == 8
    return true unless %w[c d f o s t u z |].include?(field[0])
    return true unless field[1] == ' '
    return true unless %w[a b c h m n u z |].include?(field[2])
    return true unless %w[d e j k m o u z |].include?(field[3])
    return true unless [' ', 'a', 'b', 'u', '|'].include?(field[4])
    return true unless [' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'u', 'z', '|'].include?(field[5])
    return true unless %w[a b c d e f g j k s t v w x y u z |].include?(field[6])
    return true unless [' ', 'c', 'd', 'e', 'h', 'j', 'k', 'm', 'u', 'z', '|'].include?(field[7])

    false
  end

  def microform_f007(field)
    return true unless field.length == 12
    return true unless %w[a b c d e f g h j u z |].include?(field[0])
    return true unless field[1] == ' '
    return true unless %w[a b m u |].include?(field[2])
    return true unless %w[a d f g h l m o p u z |].include?(field[3])
    return true unless %w[a b c d e u v |].include?(field[4])
    return true unless field[5..7] == '|||' || field[5..7] =~ /^[0-9]+-*$/
    return true unless %w[b c m u z |].include?(field[8])
    return true unless %w[a b c m n u z |].include?(field[9])
    return true unless %w[a b c m u |].include?(field[10])
    return true unless %w[a c d i m n p r t u z |].include?(field[11])

    false
  end

  def nonproj_graphic_f007(field)
    return true unless field.length == 5
    return true unless %w[a c d e f g h i j k l n o p q r s u v z |].include?(field[0])
    return true unless field[1] == ' '
    return true unless %w[a b c h m u z |].include?(field[2])
    return true unless %w[a b c d e f g h i l m n o p q r s t u v w z |].include?(field[3])
    return true unless [' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
                        'u', 'v', 'w', 'z', '|'].include?(field[4])

    false
  end

  def motion_pict_f007(field)
    return true unless field.length > 6
    return true unless %w[c f o r u z |].include?(field[0])
    return true unless field[1] == ' '
    return true unless %w[b c h m n u z |].include?(field[2])
    return true unless %w[a b c d e f u z |].include?(field[3])
    return true unless [' ', 'a', 'b', 'u', '|'].include?(field[4])
    return true unless [' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'u', 'z', '|'].include?(field[5])
    return true unless %w[a b c d e f g u z |].include?(field[6])
    return true unless field[7].nil? || field[7] =~ /[kmnqsuz|]/
    return true unless field[8].nil? || field[8] =~ /[a-gnz|]/
    return true unless field[9].nil? || field[9] =~ /[abnuz|]/
    return true unless field[10].nil? || field[10] =~ /[deoruz|]/
    return true unless field[11].nil? || field[11] =~ /[acdimnprtuz|]/
    return true unless field[12].nil? || field[12] =~ /[a-np-vz|]/
    return true unless field[13].nil? || field[13] =~ /[abcdnuz|]/
    return true unless field[14].nil? || field[14] =~ /[a-hklm|]/
    return true unless field[15].nil? || field[15] =~ /[cinu|]/

    inspect_date = field[16..21]
    case inspect_date
    when '||||||', '------'
      false
    when /^[0-9]+-*$/
      false
    else
      true
    end
  end

  # Kit and notated music are tested with the same method
  def kit_mus_f007(field)
    return true unless field.length == 1

    %w[u |].include?(field[0]) ? false : true
  end

  def remote_data_types
    YAML.load_file("#{ROOT_DIR}/yaml/fixed_fields/remote_data_types.yml")
  end

  def remote_f007(field)
    return true unless field.length == 10
    return true unless field[0] =~ /[u|]/
    return true unless field[1] == ' '
    return true unless field[2] =~ /[abcnuz|]/
    return true unless field[3] =~ /[abcnu|]/
    return true unless field[4] =~ /[0-9nu|]/
    return true unless field[5] =~ /[a-inuz|]/
    return true unless field[6] =~ /[abcmnuz|]/
    return true unless field[7] =~ /[abuz|]/
    return true unless remote_data_types.include? field[8..9]

    false
  end

  def recording_f007(field)
    return true unless field.length == 13
    return true unless %w[d e g i q r s t u w z |].include?(field[0])
    return true unless field[1] == ' '
    return true unless field[2] =~ /[a-fhik-pruz|]/
    return true unless field[3] =~ /[mqsuz|]/
    return true unless field[4] =~ /[mnsuz|]/
    return true unless field[5] =~ /[a-gjnosuz|]/
    return true unless field[6] =~ /[l-puz|]/
    return true unless field[7] =~ /[a-fnuz|]/
    return true unless field[8] =~ /[abdimnrstuz|]/
    return true unless field[9] =~ /[abcgilmnprswuz|]/
    return true unless field[10] =~ /[hlnu|]/
    return true unless field[11] =~ /[a-hnuz|]/
    return true unless field[12] =~ /[abdeuz|]/

    false
  end

  def text_f007(field)
    return true unless field.length == 1

    %w[a b c d u z |].include?(field[0]) ? false : true
  end

  def video_f007(field)
    return true unless field.length == 8
    return true unless %w[c d f r u z |].include?(field[0])
    return true unless field[1] == ' '
    return true unless %w[a b c m n u z |].include?(field[2])
    return true unless field[3] =~ /[a-kmopqsuvz|]/
    return true unless [' ', 'a', 'b', 'u', '|'].include?(field[4])
    return true unless [' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'u', 'z', '|'].include?(field[5])
    return true unless %w[a m o p q r u z |].include?(field[6])
    return true unless %w[k m n q s u z |].include?(field[7])

    false
  end

  def unspec_f007(field)
    return true unless field.length == 1

    %w[m u z |].include?(field[0]) ? false : true
  end

  def bad_f007?(record)
    fields = record.fields('007')
    return false if fields.empty?

    fields.each do |field|
      rec_type = field.value[0]
      specific_f007 = field.value[1..]
      return true unless specific_f007

      case rec_type
      when 'a'
        return true if map_f007(specific_f007)
      when 'c'
        return true if elec_f007(specific_f007)
      when 'd'
        return true if globe_f007(specific_f007)
      when 'f'
        return true if tactile_f007(specific_f007)
      when 'g'
        return true if proj_graphic_f007(specific_f007)
      when 'h'
        return true if microform_f007(specific_f007)
      when 'k'
        return true if nonproj_graphic_f007(specific_f007)
      when 'm'
        return true if motion_pict_f007(specific_f007)
      when 'o' || 'q'
        return true if kit_mus_f007(specific_f007)
      when 'r'
        return true if remote_f007(specific_f007)
      when 's'
        return true if recording_f007(specific_f007)
      when 't'
        return true if text_f007(specific_f007)
      when 'v'
        return true if video_f007(specific_f007)
      when 'z'
        return true if unspec_f007(specific_f007)
      else
        return true
      end
    end
    false
  end

  def specific_f008_error?(record_type:, specific_f008:)
    case record_type
    when 'book'
      book_f008_error?(specific_f008)
    when 'computer_file'
      comp_f008_error?(specific_f008)
    when 'map'
      map_f008_error?(specific_f008)
    when 'music'
      music_f008_error?(specific_f008)
    when 'continuing_resource'
      continuing_resource_f008_error?(specific_f008)
    when 'visual'
      visual_f008_error?(specific_f008)
    when 'mixed'
      mix_mat_f008_error?(specific_f008)
    end
  end

  def bad_f008?(record)
    hash = {}
    hash[:valid] = true
    hash[:errors] = []
    field = record['008'].value

    if field.length != 40
      hash[:valid] = false
      hash[:errors] << 'Invalid 008 length'
      return hash
    end

    if global_f008_error?(field)
      hash[:valid] = false
      hash[:errors] << 'Invalid value in global 008 (positions 0-17, 35-39)'
    end

    record_type = record_type(record.leader[6..7])
    specific_f008 = field[18..34]
    if specific_f008_error?(record_type: record_type, specific_f008: specific_f008)
      hash[:valid] = false
      hash[:errors] << 'Invalid value in the specific 008 (positions 18-34)'
    end
    hash
  end

  ### Replace obsolete values with current values when possible
  def fix_f007(record)
    target_fields = record.fields('007')
    return record if target_fields.empty?

    target_fields.each do |field|
      field_index = record.fields.index(field)
      field_value = field.value
      rec_type = field_value[0]
      next unless %w[a c d f g h k m o q r s t v z].include? rec_type

      specific_f007 = field_value[1..]
      next unless specific_f007

      fixed_f007 = ''.dup
      fixed_f007 << rec_type
      case rec_type
      when 'a'
        fixed_f007 << fix_map_f007(specific_f007)
      when 'c'
        fixed_f007 << fix_electronic_f007(specific_f007)
      when 'd'
        fixed_f007 << fix_globe_f007(specific_f007)
      when 'f'
        fixed_f007 << fix_tactile_f007(specific_f007)
      when 'g'
        fixed_f007 << fix_proj_f007(specific_f007)
      when 'h'
        fixed_f007 << fix_microform_f007(specific_f007)
      when 'k'
        fixed_f007 << fix_nonproj_f007(specific_f007)
      when 'm'
        fixed_f007 << fix_motion_pic_f007(specific_f007)
      when 'o'
        fixed_f007 << fix_kit_f007(specific_f007)
      when 'q'
        fixed_f007 << fix_notated_mus_f007(specific_f007)
      when 'r'
        fixed_f007 << fix_remote_f007(specific_f007)
      when 's'
        fixed_f007 << fix_sound_rec_f007(specific_f007)
      when 't'
        fixed_f007 << fix_text_f007(specific_f007)
      when 'v'
        fixed_f007 << fix_video_f007(specific_f007)
      when 'z'
        fixed_f007 << fix_unspec_f007(specific_f007)
      end
      record.fields[field_index] = MARC::ControlField.new('007', fixed_f007)
    end
    record
  end

  def fix_map_f007(specific_f007)
    return specific_f007 unless specific_f007.length == 7

    fixed_field = ''.dup
    mat_designation = specific_f007[0]
    color = specific_f007[2]
    color = color.gsub('b', 'c')
    medium = specific_f007[3]
    medium = medium.gsub(/[^a-gijlnp-z|]/, 'u')
    repro_type = specific_f007[4]
    repro_type = repro_type.gsub(/[^fnuz|]/, 'u')
    prod_details = specific_f007[5]
    prod_details = prod_details.gsub(/[^abcduz|]/, 'u')
    aspect = specific_f007[6]
    aspect = aspect.gsub('u', '|')
    fixed_field << mat_designation
    fixed_field << ' '
    fixed_field << color
    fixed_field << medium
    fixed_field << repro_type
    fixed_field << prod_details
    fixed_field << aspect
    fixed_field
  end

  def fix_electronic_f007(specific_f007)
    return specific_f007 unless specific_f007.length > 4

    fixed_field = ''.dup
    mat_designation = specific_f007[0]
    mat_designation = mat_designation.gsub(/[^a-fhjkmorsuz|]/, 'u')
    color = specific_f007[2]
    color = color.gsub(/[^abcghmnuz|]/, 'u')
    dimensions = specific_f007[3]
    dimensions = dimensions.gsub(/[^aegijnouvz|]/, 'u')
    sound = specific_f007[4]
    sound = sound.gsub(/[^ au|]/, 'u')
    fixed_field << mat_designation
    fixed_field << ' '
    fixed_field << color
    fixed_field << dimensions
    fixed_field << sound
    return fixed_field if specific_f007.length == 5

    bit_depth = specific_f007[5..7]
    unless %w[mmm nnn --- |||].include? bit_depth
      bit_depth =~ /^[0-9]{3}$/ ? bit_depth : '---'
    end
    fixed_field << bit_depth
    formats = specific_f007[8]
    return fixed_field unless formats

    formats = formats.gsub(/[^amu|]/, 'u')
    fixed_field << formats
    quality = specific_f007[9]
    return fixed_field unless quality

    quality = quality.gsub(/[^anpu|]/, 'u')
    fixed_field << quality
    source = specific_f007[10]
    return fixed_field unless source

    source = source.gsub(/[^abcdmnu|]/, 'u')
    fixed_field << source
    compression = specific_f007[11]
    return fixed_field unless compression

    compression = compression.gsub(/[^abdmu|]/, 'u')
    fixed_field << compression
    reformatting = specific_f007[12]
    return fixed_field unless reformatting

    reformatting = reformatting.gsub(/[^anpru|]/, 'u')
    fixed_field << reformatting
    fixed_field
  end

  def fix_globe_f007(specific_f007)
    return specific_f007 unless specific_f007.length == 5

    fixed_field = ''.dup
    mat_designation = specific_f007[0]
    mat_designation = mat_designation.gsub(/[^abcdeuz|]/, 'u')
    color = specific_f007[2]
    color = color.gsub('b', 'c')
    medium = specific_f007[3]
    medium = medium.gsub(/[^a-gilnpuvwz|]/, 'u')
    repro_type = specific_f007[4]
    repro_type = repro_type.gsub(/[^fnuz|]/, 'u')
    fixed_field << mat_designation
    fixed_field << ' '
    fixed_field << color
    fixed_field << medium
    fixed_field << repro_type
    fixed_field
  end

  def fix_tactile_f007(specific_f007)
    return specific_f007 unless specific_f007.length == 9

    fixed_field = ''.dup
    mat_designation = specific_f007[0]
    mat_designation = mat_designation.gsub(/[^abcduz|]/, 'u')
    writing = specific_f007[2..3]
    unless writing == '||'
      writing_chars = writing.chars.select { |c| c =~ /[a-emnuz]/ }.sort.join('')
      writing = writing_chars.ljust(2)
    end
    contraction = specific_f007[4]
    contraction = contraction.gsub(/[^abmnuz|]/, 'u')
    music = specific_f007[5..7]
    unless music == '|||'
      music_chars = music.chars.select { |c| c =~ /[a-lnuz]/ }.sort.join('')
      music = music_chars.ljust(3)
    end
    special = specific_f007[8]
    special = special.gsub(/[^abnuz|]/, 'u')
    fixed_field << mat_designation
    fixed_field << ' '
    fixed_field << writing
    fixed_field << contraction
    fixed_field << music
    fixed_field << special
    fixed_field
  end

  def fix_proj_f007(specific_f007)
    return specific_f007 unless specific_f007.length == 8

    fixed_field = ''.dup
    mat_designation = specific_f007[0]
    mat_designation = mat_designation.gsub(/[^cdfostuz|]/, 'u')
    color = specific_f007[2]
    color = color.gsub(/[^abchmnuz|]/, 'u')
    base = specific_f007[3]
    base = base.gsub(/[^dejkmouz|]/, 'u')
    sound_on_medium = specific_f007[4]
    sound_on_medium = sound_on_medium.gsub(/[^ abu|]/, 'u')
    sound_medium = specific_f007[5]
    sound_medium = sound_medium.gsub(/[^ a-iuz|]/, 'u')
    dimensions = specific_f007[6]
    dimensions = dimensions.gsub(/[^a-gjkst-z|]/, 'u')
    support = specific_f007[7]
    support = support.gsub(/[^ cdehjkmuz|]/, 'u')
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

  def fix_microform_f007(specific_f007)
    return specific_f007 unless specific_f007.length == 12

    fixed_field = ''.dup
    mat_designation = specific_f007[0]
    mat_designation = mat_designation.gsub(/[^a-hjuz|]/, 'u')
    aspect = specific_f007[2]
    aspect = aspect.gsub(/[^abmu|]/, 'u')
    dimensions = specific_f007[3]
    dimensions = dimensions.gsub(/[^adfghlmopuz|]/, 'u')
    reduction_range = specific_f007[4]
    reduction_range = reduction_range.gsub(/[^a-euv|]/, 'u')
    reduction_ratio = specific_f007[5..7]
    unless %w[--- |||].include? reduction_ratio
      reduction_nums = reduction_ratio.chars.select { |c| c =~ /[0-9]/ }.join('')
      reduction_ratio = reduction_nums.ljust(3, '-')
    end
    color = specific_f007[8]
    color = color.gsub(/[^bcmuz|]/, 'u')
    emulsion = specific_f007[9]
    emulsion = emulsion.gsub(/[^abcmnuz|]/, 'u')
    generation = specific_f007[10]
    generation = generation.gsub(/[^abcmu|]/, 'u')
    base = specific_f007[11]
    base = base.gsub(/[^abcdimnprtuz|]/, 'u')
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

  def fix_nonproj_f007(specific_f007)
    return specific_f007 unless specific_f007.length == 5

    fixed_field = ''.dup
    mat_designation = specific_f007[0]
    mat_designation = mat_designation.gsub(/[^ac-ln-suvz|]/, 'u')
    color = specific_f007[2]
    color = color.gsub(/[^abchmuz|]/, 'u')
    primary_support = specific_f007[3]
    primary_support = primary_support.gsub(/[^a-il-wz|]/, 'u')
    secondary_support = specific_f007[4]
    secondary_support = secondary_support.gsub(/[^ a-il-wz|]/, 'u')
    fixed_field << mat_designation
    fixed_field << ' '
    fixed_field << color
    fixed_field << primary_support
    fixed_field << secondary_support
    fixed_field
  end

  def fix_motion_pic_f007(specific_f007)
    return specific_f007 unless specific_f007.length > 6

    fixed_field = ''.dup
    mat_designation = specific_f007[0]
    mat_designation = mat_designation.gsub(/[^cdforuz|]/, 'u')
    color = specific_f007[2]
    color = color.gsub(/[^bchmnuz|]/, 'u')
    presentation = specific_f007[3]
    presentation = presentation.gsub(/[^a-fuz|]/, 'u')
    sound_on_medium = specific_f007[4]
    sound_on_medium = sound_on_medium.gsub(/[^ abu|]/, 'u')
    sound_medium = specific_f007[5]
    sound_medium = sound_medium.gsub(/[^ a-iuz|]/, 'u')
    dimensions = specific_f007[6]
    dimensions = dimensions.gsub(/[^a-guz|]/, 'u')
    fixed_field << mat_designation
    fixed_field << ' '
    fixed_field << color
    fixed_field << presentation
    fixed_field << sound_on_medium
    fixed_field << sound_medium
    fixed_field << dimensions
    return fixed_field if specific_f007.length == 7

    channels = specific_f007[7]
    channels = channels.gsub(/[^kmnqsuz|]/, 'u')
    fixed_field << channels
    elements = specific_f007[8]
    return fixed_field unless elements

    elements = elements.gsub('h', 'z')
    elements = elements.gsub(/[^abcdefgnz|]/, '|')
    fixed_field << elements
    aspect = specific_f007[9]
    return fixed_field unless aspect

    aspect = aspect.gsub(/[^abnuz|]/, 'u')
    fixed_field << aspect
    generation = specific_f007[10]
    return fixed_field unless generation

    generation = generation.gsub(/[^deoruz|]/, 'u')
    fixed_field << generation
    base = specific_f007[11]
    return fixed_field unless base

    base = base.gsub(/[^acdimnprtuz|]/, 'u')
    fixed_field << base
    refined = specific_f007[12]
    return fixed_field unless refined

    refined = refined.gsub(/[^a-np-vz|]/, 'u')
    fixed_field << refined
    stock = specific_f007[13]
    return fixed_field unless stock

    stock = stock.gsub(/[^abcdnuz|]/, 'u')
    fixed_field << stock
    deterioration = specific_f007[14]
    return fixed_field unless deterioration

    deterioration = deterioration.gsub(/[^abcdefghklm|]/, '|')
    fixed_field << deterioration
    completeness = specific_f007[15]
    return fixed_field unless completeness

    completeness = completeness.gsub(/[^cinu|]/, 'u')
    fixed_field << completeness
    return fixed_field if specific_f007.length == 16

    inspect_date = specific_f007[16..21]
    inspect_date = inspect_date.gsub(/[^0-9-]/, '-')
    fixed_field << inspect_date
    fixed_field
  end

  def fix_kit_f007(specific_f007)
    mat_designation = specific_f007[0]
    mat_designation.gsub(/[^u|]/, 'u')
  end

  def fix_notated_mus_f007(specific_f007)
    mat_designation = specific_f007[0]
    mat_designation.gsub(/[^u|]/, 'u')
  end

  def fix_remote_f007(specific_f007)
    return specific_f007 unless specific_f007.length == 10

    fixed_field = ''.dup
    mat_designation = specific_f007[0]
    mat_designation = mat_designation.gsub(/[^u|]/, 'u')
    altitude = specific_f007[2]
    altitude = altitude.gsub(/[^abcnuz|]/, 'u')
    attitude = specific_f007[3]
    attitude = attitude.gsub(/[^abcnuz|]/, 'u')
    clouds = specific_f007[4]
    clouds = clouds.gsub(/[^0-9nu|]/, 'u')
    construction = specific_f007[5]
    construction = construction.gsub(/[^a-inuz|]/, 'u')
    use = specific_f007[6]
    use = use.gsub(/[^abcmnuz|]/, 'u')
    sensor = specific_f007[7]
    sensor = sensor.gsub(/[^abuz|]/, 'u')
    data_type = specific_f007[8..9]
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

  def fix_sound_rec_f007(specific_f007)
    return specific_f007 unless specific_f007.length == 13

    fixed_field = ''.dup
    mat_designation = specific_f007[0].dup
    mat_designation = case mat_designation
                      when 'c'
                        'e'
                      when 'f'
                        'i'
                      else
                        mat_designation
                      end
    mat_designation = mat_designation.gsub(/[^degiq-uwz|]/, 'u')
    speed = specific_f007[2]
    speed = speed.gsub(/[^a-fhik-pruz|]/, 'u')
    channels = specific_f007[3]
    channels = channels.gsub(/[^mqsuz|]/, 'u')
    groove = specific_f007[4]
    groove = groove.gsub(/[^mnsuz|]/, 'u')
    dimensions = specific_f007[5]
    dimensions = dimensions.gsub(/[^abcdefgjnosuz|]/, 'u')
    width = specific_f007[6]
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
    width = width.gsub(/[^l-puz|]/, 'u')
    configuration = specific_f007[7]
    configuration = configuration.gsub(/[^abcdefnuz|]/, 'u')
    disc_kind = specific_f007[8]
    disc_kind = disc_kind.gsub(/[^abdimnrstuz|]/, 'u')
    material = specific_f007[9]
    material = material.gsub(/[^abcgilmnprswuz|]/, 'u')
    cutting = specific_f007[10]
    cutting = cutting.gsub(/[^hlnu|]/, 'u')
    playback = specific_f007[11]
    playback = playback.gsub(/[^abcdefghnuz|]/, 'u')
    storage = specific_f007[12]
    storage = storage.gsub(/[^abdeuz|]/, 'u')
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

  def fix_text_f007(specific_f007)
    mat_designation = specific_f007[0]
    mat_designation.gsub(/[^abcduz|]/, 'u')
  end

  def fix_video_f007(specific_f007)
    return specific_f007 unless specific_f007.length == 8

    fixed_field = ''.dup
    mat_designation = specific_f007[0]
    mat_designation = mat_designation.gsub(/[^cdfruz|]/, 'u')
    color = specific_f007[2]
    color = color.gsub(/[^abcmnuz|]/, 'u')
    format = specific_f007[3]
    format = format.gsub(/[^a-kmopqsuvz|]/, 'u')
    sound_on_medium = specific_f007[4]
    sound_on_medium = sound_on_medium.gsub(/[^ abu|]/, 'u')
    sound_medium = specific_f007[5]
    sound_medium = sound_medium.gsub(/[^ abcdefghiuz|]/, 'u')
    dimensions = specific_f007[6]
    dimensions = dimensions.gsub(/[^amopqruz|]/, 'u')
    channels = specific_f007[7]
    channels = channels.gsub(/[^kmnqsuz|]/, 'u')
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

  def fix_unspec_f007(specific_f007)
    mat_designation = specific_f007[0]
    mat_designation.gsub(/[^muz|]/, 'u')
  end

  def contents_chars
    %w[a b c d e f g h i k l m n o p q r s t u v w y z 5 6]
  end

  def fix_contents_chars(contents)
    return contents if contents =~ /\|+$/

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

  ### Replace obsolete values with current values when possible
  def fix_f006(record)
    record.fields.each_with_index do |field, field_index|
      next unless field.tag == '006'
      next if field.value.size != 18

      rec_type = field.value[0]
      next unless rec_type =~ /[ac-gijkmoprst]/

      new_value = rec_type
      specific_f006 = field.value[1..]
      fixed_specific_f006 = case rec_type
                            when 'a', 't'
                              fix_book_f008(specific_f006)
                            when 'c', 'd', 'i', 'j'
                              fix_music_f008(specific_f006)
                            when 'e', 'f'
                              fix_map_f008(specific_f006)
                            when 'g', 'k', 'o', 'r'
                              fix_visual_f008(specific_f006)
                            when 'm'
                              fix_comp_f008(specific_f006)
                            when 'p'
                              fix_mix_mat_f008(specific_f006)
                            when 's'
                              fix_continuing_resource_f008(specific_f006)
                            end
      new_value << fixed_specific_f006
      record.fields[field_index] = MARC::ControlField.new('006', new_value)
    end
    record
  end

  def fix_specific_f008(record_type:, specific_f008:)
    case record_type
    when 'book'
      fix_book_f008(specific_f008)
    when 'computer_file'
      fix_comp_f008(specific_f008)
    when 'map'
      fix_map_f008(specific_f008)
    when 'music'
      fix_music_f008(specific_f008)
    when 'continuing_resource'
      fix_continuing_resource_f008(specific_f008)
    when 'visual'
      fix_visual_f008(specific_f008)
    when 'mixed'
      fix_mix_mat_f008(specific_f008)
    end
  end

  ### Replace obsolete values with current values when possible
  def fix_f008(record)
    target_fields = record.fields('008')
    record_type = record_type(record.leader[6..7])
    return record if target_fields.size != 1
    return record unless record_type

    field = target_fields.first
    return record if field.value.size != 40

    field_index = record.fields.index(field)
    new_value = field.value[0..17]
    new_value << fix_specific_f008(record_type: record_type, specific_f008: field.value[18..34])
    new_value << field.value[35..37]
    modified = field.value[38]
    modified = '|' if modified == 'u'
    new_value << modified
    cat_source = field.value[39]
    new_value << case cat_source
                 when 'a', 'b', 'l'
                   ' '
                 when 'o'
                   'd'
                 else
                   cat_source
                 end
    record.fields[field_index] = MARC::ControlField.new('008', new_value)
    record
  end

  def fix_book_f008(field)
    fixed_field = ''.dup
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
    audience = audience.gsub(/[uv]/, 'j')
    fixed_field << audience
    fixed_field << item_form
    contents = fix_contents_chars(contents)
    fixed_field << contents
    gov_pub = gov_pub.gsub('n', 'o')
    fixed_field << gov_pub
    fixed_field << conf_pub
    fixed_field << festschrift
    fixed_field << index_code
    fixed_field << ' '
    lit_form = lit_form.gsub(' ', '0')
    fixed_field << lit_form
    fixed_field << biog
    fixed_field.gsub('-', '|')
  end

  def fix_comp_f008(field)
    fixed_field = ''.dup
    audience = field[4]
    item_form = field[5]
    type = field[8]
    gov_pub = field[10]
    fixed_field << '    '
    audience = audience.gsub(/[uv]/, 'j')
    fixed_field << audience
    fixed_field << item_form
    fixed_field << '  '
    fixed_field << type
    fixed_field << ' '
    gov_pub = gov_pub.gsub('n', 'o')
    fixed_field << gov_pub
    fixed_field << '      '
    fixed_field.gsub('-', '|')
  end

  def fix_map_f008(field)
    fixed_field = ''.dup
    relief = field[0..3]
    proj = field[4..5]
    type = field[7]
    gov_pub = field[10]
    item_form = field[11]
    index_code = field[13]
    format = field[15..16]
    unless relief == '||||'
      relief = relief.gsub('h', 'c')
      relief_chars = relief.chars.select { |c| %w[a b c d e f g i j k m z].include? c }.sort.join('')
      relief = relief_chars.ljust(4)
    end
    fixed_field << relief
    fixed_field << proj
    fixed_field << ' '
    fixed_field << type
    fixed_field << '  '
    gov_pub = gov_pub.gsub('n', 'o')
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
    fixed_field.gsub('-', '|')
  end

  def fix_music_f008(field)
    fixed_field = ''.dup
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
    audience = audience.gsub(/[uv]/, 'j')
    fixed_field << audience
    fixed_field << item_form
    unless accompanying == '||||||'
      accompanying = accompanying.gsub('j', 'i')
      accompanying_chars = accompanying.chars.select { |c| %w[a b c d e f g h i k r s z].include? c }.sort.join('')
      accompanying = accompanying_chars.ljust(6)
    end
    fixed_field << accompanying
    unless ['||', '  '].include? lit_text
      lit_text_chars = lit_text.chars.select do |c|
        %w[a b c d e f g h i j k l m n o p r s t z].include? c
      end.sort.join('')
      lit_text = lit_text_chars.ljust(2)
    end
    fixed_field << lit_text
    fixed_field << ' '
    fixed_field << transpose
    fixed_field << ' '
    fixed_field.gsub('-', '|')
  end

  def fix_continuing_resource_f008(field)
    fixed_field = ''.dup
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
    gov_pub = gov_pub.gsub('n', 'o')
    fixed_field << gov_pub
    fixed_field << conf_pub
    fixed_field << '   '
    fixed_field << orig_script
    fixed_field << entry
    fixed_field.gsub('-', '|')
  end

  def fix_visual_f008(field)
    fixed_field = ''.dup
    runtime = field[0..2]
    audience = field[4]
    gov_pub = field[10]
    item_form = field[11]
    visual_type = field[15]
    technique = field[16]
    fixed_field << runtime
    fixed_field << ' '
    audience = audience.gsub(/[uv]/, 'j')
    fixed_field << audience
    fixed_field << '     '
    gov_pub = gov_pub.gsub('n', 'o')
    fixed_field << gov_pub
    fixed_field << item_form
    fixed_field << '   '
    visual_type = visual_type.gsub('e', 'v')
    fixed_field << visual_type
    technique = technique.gsub(' ', 'n')
    fixed_field << technique
    fixed_field
  end

  def fix_mix_mat_f008(field)
    fixed_field = ''.dup
    item_form = field[5]
    fixed_field << '     '
    fixed_field << item_form
    fixed_field << '           '
    fixed_field.gsub('-', '|')
  end
end
