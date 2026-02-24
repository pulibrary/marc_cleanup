# frozen_string_literal: true

module MarcCleanup
  def no_f001?(record)
    record['001'].nil?
  end

  def fixed_field_char_errors?(record)
    fields = record.fields('001'..'009').map(&:value)
    bad_fields = fields.reject { |value| value.bytesize == value.chars.size }
    bad_fields += fields.grep(/[^a-z0-9 |.A-Z-]/)
    !bad_fields.empty?
  end

  def multiple_no_f008?(record)
    record.fields('008').size != 1
  end

  def date2_f008_error?(date2, date_type)
    case date_type
    when 'e'
      date2 =~ /^[0-9]+\s*$/ ? false : true
    else
      ['||||', '    '].include?(date2) || date2 =~ /^[0-9u]{4}$/ ? false : true
    end
  end

  def date_f008_error?(field)
    date_type = field[6]
    date1 = field[7..10]
    date2 = field[11..14]
    return true unless ['||||', '    '].include?(date1) || date1 =~ /^[0-9u]{4}$/
    return true unless date_type =~ /[b-eikmnp-u|]/

    date2_f008_error?(date2, date_type)
  end

  def global_f008_error?(field)
    return true unless field[0..5] =~ /^[0-9]{6}$/ # date entered
    return true if date_f008_error?(field)
    return true unless (PLACE_CODES + ['|||']).include?(field[15..17]) # place of publication
    return true unless (LANGUAGE_CODES + ['|||']).include?(field[35..37]) # language code
    return true unless [' ', 'd', 'o', 'r', 's', 'x', '|'].include?(field[38]) # modified record
    return true unless [' ', 'c', 'd', 'u', '|'].include?(field[39]) # cataloging source

    false
  end

  def ideal_book_f008
    /
      ^(?:[|]{4}|[#{BOOK_ILLUSTRATION.join}]{4})
      [#{AUDIENCE_CODES.join}][#{ITEM_FORM_CODES.join}]
      (?:[|]{4}|[#{BOOK_CONTENTS.join}]{4})
      [#{GOV_PUB.join}]
      [01|]{3} # conference, festschrift, index
      [ |] # undefined
      [#{BOOK_LIT_FORM.join}][#{BOOK_BIOGRAPHY.join}]$
    /x
  end

  def book_f008_error?(field)
    !ideal_book_f008.match?(field)
  end

  def ideal_comp_f008
    /
      ^(?:[|]{4}|[ ]{4}) # undefined
      [#{AUDIENCE_CODES.join}]
      [ oq|] # limited item form for computer file
      (?:[|]{2}|[ ]{2}) # undefined
      [#{COMPUTER_FILE_TYPE.join}]
      [ |] # undefined
      [#{GOV_PUB.join}]
      (?:[|]{6}|[ ]{6})$ # undefined
    /x
  end

  def comp_f008_error?(field)
    !ideal_comp_f008.match?(field)
  end

  def ideal_map_f008
    /
      (?:[|]{4}|[#{MAP_RELIEF.join}]{4})(?:#{MAP_PROJECTION.join('|')}|[|]{2})
      [| ][#{MAP_TYPE.join}] # first character is undefined
      (?:[|]{2}|\s{2}) # undefined
      [#{GOV_PUB.join}][#{ITEM_FORM_CODES.join}]
      [| ] # undefined
      [01|] # index
      [| ] # undefined
      (?:[|]{2}|[#{MAP_SPECIAL_FORMAT.join}]{2})$
    /x
  end

  def map_f008_error?(field)
    !ideal_map_f008.match?(field)
  end

  def ideal_music_f008
    /
      ^(?:#{MUSIC_COMPOSITION.join('|')}|[|]{2})
      [#{MUSIC_FORMAT.join}][#{MUSIC_PART.join}]
      [#{AUDIENCE_CODES.join}][#{ITEM_FORM_CODES.join}]
      (?:[|]{6}|[#{MUSIC_ACCOMPANY.join}]{6})
      (?:[|]{2}|[#{MUSIC_LITERARY_TEXT.join}]{2})
      [| ] # undefined
      [#{MUSIC_TRANSPOSITION.join}]
      [| ]$ # undefined
    /x
  end

  def music_f008_error?(field)
    !ideal_music_f008.match?(field)
  end

  def ideal_continuing_resource_f008
    /
      ^[#{CR_FREQUENCY.join}][#{CR_REGULARITY.join}]
      [| ] # undefined
      [#{CR_TYPE.join}][#{CR_ORIGINAL_FORM.join}]
      [#{ITEM_FORM_CODES.join}][#{CR_WORK_NATURE.join}]
      (?:[#{CR_CONTENTS.join}]{3}|[|]{3})
      [#{GOV_PUB.join}][01|] # conference publication
      (?:[ ]{3}|[|]{3}) # undefined
      [#{CR_ORIGINAL_SCRIPT.join}][012|]$ # entry convention
    /x
  end

  def continuing_resource_f008_error?(field)
    !ideal_continuing_resource_f008.match?(field)
  end

  def ideal_visual_f008
    /
      ^(?:n{3}|-{3}|[|]{3}|[0-9]{3}) # runtime
      [| ] # undefined
      [#{AUDIENCE_CODES.join}]
      (?:[ ]{5}|[|]{5}) # undefined
      [#{GOV_PUB.join}][#{ITEM_FORM_CODES.join}]
      (?:[ ]{3}|[|]{3}) # undefined
      [#{VISUAL_TYPE.join}][#{VISUAL_TECHNIQUE.join}]$
    /x
  end

  def visual_f008_error?(field)
    !ideal_visual_f008.match?(field)
  end

  def ideal_mix_mat_f008
    /
      (?:[ ]{5}|[|]{5}) # undefined
      [#{ITEM_FORM_CODES.join}]
      (?:[ ]{11}|[|]{11})$ # undefined
    /x
  end

  def mix_mat_f008_error?(field)
    !ideal_mix_mat_f008.match?(field)
  end

  def record_type(leader_portion)
    RECORD_TYPES.find { |_type, values| values.include?(leader_portion) }.to_a[0]
  end

  def bad_f005?(record)
    field = record['005']
    return false unless field

    field.value =~ /^[0-9]{14}\.[0-9]$/ ? false : true
  end

  def record_type_f006
    {
      'book' => %w[a t],
      'computer_file' => %w[m],
      'map' => %w[e f],
      'music' => %w[c d i j],
      'continuing_resource' => %w[s],
      'visual' => %w[g k o r],
      'mixed' => %w[p]
    }
  end

  # Uses same methods as the specific 008 methods
  def bad_f006?(record)
    fields = record.fields('006')
    return true if fields.any? { |field| field.value.size != 18 }

    fields.each do |field|
      record_type = record_type_f006.find { |_value, codes| codes.include?(field.value[0]) }[0]
      return true if specific_f008_error?(record_type: record_type, specific_f008: field.value[1..])
    end
    false
  end

  def ideal_map_f007
    /
      ^[#{MAP_MATERIAL_DESIGNATION.join}]
      [ ] # undefined
      [#{MAP_COLOR.join}]
      [#{MAP_PHYSICAL_MEDIUM.join}]
      [#{MAP_REPRODUCTION_TYPE.join}]
      [#{MAP_REPRODUCTION_DETAILS.join}]
      [#{MAP_POSITIVE_ASPECT.join}]$
    /x
  end

  def map_f007_error?(field)
    !ideal_map_f007.match?(field)
  end

  def ideal_elec_f007
    /
      ^[#{ELECTRONIC_MATERIAL_DESIGNATION.join}]
      [ ] # undefined
      [#{ELECTRONIC_COLOR.join}][#{ELECTRONIC_DIMENSION.join}]
      [#{ELECTRONIC_SOUND.join}]
      (?:m{3}|n{3}|-{3}|[|]{3}|[0-9]{3}) # image bit depth
      [#{ELECTRONIC_FILE_FORMAT.join}][#{ELECTRONIC_QA.join}]
      [#{ELECTRONIC_SOURCE.join}][#{ELECTRONIC_COMPRESSION.join}]
      [#{ELECTRONIC_REFORMATTING.join}]$
    /x
  end

  def elec_f007_error?(field)
    !ideal_elec_f007.match?(field)
  end

  def ideal_globe_f007
    /
      ^[#{GLOBE_MATERIAL_DESIGNATION.join}]
      [ ] # undefined
      [#{GLOBE_COLOR.join}]
      [#{GLOBE_PHYSICAL_MEDIUM.join}]
      [#{GLOBE_REPRODUCTION_TYPE.join}]$
    /x
  end

  def globe_f007_error?(field)
    !ideal_globe_f007.match?(field)
  end

  def ideal_tactile_f007
    /
      ^[#{TACTILE_MATERIAL_DESIGNATION.join}]
      [ ] # undefined
      (?:[|]{2}|[#{TACTILE_BRAILLE_CLASS.join}]{2})
      [#{TACTILE_CONTRACTION.join}]
      (?:[|]{3}|[#{TACTILE_BRAILLE_MUSIC.join}]{3})
      [#{TACTILE_PHYSICAL_CHARACTERISTICS.join}]$
    /x
  end

  def tactile_f007_error?(field)
    !ideal_tactile_f007.match?(field)
  end

  def ideal_proj_graphic_f007
    /
      ^[#{PROJ_GRAPHIC_MATERIAL_DESIGNATION.join}]
      [ ] # undefined
      [#{PROJ_GRAPHIC_COLOR.join}]
      [#{PROJ_GRAPHIC_EMULSION.join}]
      [#{PROJ_GRAPHIC_SOUND_SEPARATE.join}]
      [#{SOUND_MEDIUM.join}]
      [#{PROJ_GRAPHIC_DIMENSION.join}]
      [#{PROJ_GRAPHIC_SUPPORT.join}]$
    /x
  end

  def proj_graphic_f007_error?(field)
    !ideal_proj_graphic_f007.match?(field)
  end

  def ideal_microform_f007
    /
      ^[#{MICROFORM_MATERIAL_DESIGNATION.join}]
      [ ] # undefined
      [#{MICROFORM_POSITIVE_ASPECT.join}]
      [#{MICROFORM_DIMENSION.join}][#{MICROFORM_REDUCTION_RANGE.join}]
      (?:[0-9]--|[0-9]{2}-|[0-9]{3}|-{3}|[|]{3})
      [#{MICROFORM_COLOR.join}][#{MICROFORM_EMULSION.join}]
      [#{MICROFORM_GENERATION.join}]
      [#{MICROFORM_BASE.join}]$
    /x
  end

  def microform_f007_error?(field)
    !ideal_microform_f007.match?(field)
  end

  def ideal_nonproj_graphic_f007
    /
      ^[#{NONPROJ_GRAPHIC_MATERIAL_DESIGNATION.join}]
      [ ] # undefined
      [#{NONPROJ_GRAPHIC_COLOR.join}]
      [#{NONPROJ_GRAPHIC_PRIMARY_SUPPORT.join}]
      [#{NONPROJ_GRAPHIC_SECONDARY_SUPPORT.join}]$
    /x
  end

  def nonproj_graphic_f007_error?(field)
    !ideal_nonproj_graphic_f007.match?(field)
  end

  def ideal_required_motion_pict_f007
    /
      ^[#{MOTION_PICT_MATERIAL_DESIGNATION.join}]
      [ ] # undefined
      [#{MOTION_PICT_COLOR.join}]
      [#{MOTION_PICT_FORMAT.join}]
      [#{MOTION_PICT_SOUND_SEPARATE.join}]
      [#{SOUND_MEDIUM.join}]
      [#{MOTION_PICT_DIMENSION.join}]
    /x
  end

  def ideal_optional_motion_pict_f007
    /
      ^[#{MOTION_PICT_PLAYBACK_CHANNEL.join}]
      [#{MOTION_PICT_PROD_ELEMENTS.join}]?
      [#{MOTION_PICT_POSITIVE_ASPECT.join}]?
      [#{MOTION_PICT_GENERATION.join}]?[#{MOTION_PICT_BASE.join}]?
      [#{MOTION_PICT_REFINED_COLOR.join}]?[#{MOTION_PICT_COLOR_STOCK.join}]?
      [#{MOTION_PICT_DETERIORATION.join}]?
      [#{MOTION_PICT_COMPLETENESS.join}]?
      (?:[0-9]{1,6}-*|-{6}|[|]{6})?$ # film inspection date
    /x
  end

  def motion_pict_f007_error?(field)
    return true unless ideal_required_motion_pict_f007.match?(field)

    !ideal_optional_motion_pict_f007.match?(field[7..]) && field.size > 6
  end

  # Kit and notated music are tested with the same method
  def kit_mus_f007_error?(field)
    return true unless field.length == 1

    !%w[u |].include?(field[0])
  end

  def ideal_remote_f007
    /
      ^[u|] # specific material designation
      [ ] # undefined
      [#{REMOTE_ALTITUDE.join}]
      [#{REMOTE_ATTITUDE.join}]
      [#{REMOTE_CLOUD_COVER.join}]
      [#{REMOTE_PLATFORM_TYPE.join}]
      [#{REMOTE_PLATFORM_USE.join}]
      [#{REMOTE_SENSOR_TYPE.join}]
      #{REMOTE_DATA_TYPES.join('|')}|[|]{2}$
    /x
  end

  def remote_f007_error?(field)
    !ideal_remote_f007.match?(field)
  end

  def ideal_sound_recording_f007
    /
      ^[#{SOUND_RECORDING_MATERIAL_DESIGNATION.join}]
      [ ] # undefined
      [#{SOUND_RECORDING_SPEED.join}][#{SOUND_RECORDING_PLAYBACK_CHANNELS.join}]
      [#{SOUND_RECORDING_GROOVE_WIDTH.join}][#{SOUND_RECORDING_DIMENSIONS.join}]
      [#{SOUND_RECORDING_TAPE_WIDTH.join}][#{SOUND_RECORDING_TAPE_CONFIGURATION.join}]
      [#{SOUND_RECORDING_DISC_KIND.join}][#{SOUND_RECORDING_MATERIAL_KIND.join}]
      [#{SOUND_RECORDING_CUTTING_KIND.join}][#{SOUND_RECORDING_PLAYBACK_CHARACTERISTICS.join}]
      [#{SOUND_RECORDING_CAPTURE_STORAGE_TECHNIQUE.join}]$
    /x
  end

  def sound_recording_f007_error?(field)
    !ideal_sound_recording_f007.match?(field)
  end

  def text_f007_error?(field)
    regex = /
              ^[#{TEXT_MATERIAL_DESIGNATION.join}]$
            /x
    !regex.match?(field)
  end

  def ideal_video_f007
    /
      ^[#{VIDEO_MATERIAL_DESIGNATION.join}]
      [ ] # undefined
      [#{VIDEO_COLOR.join}]
      [#{VIDEO_FORMAT.join}]
      [#{VIDEO_SOUND_SEPARATE.join}]
      [#{SOUND_MEDIUM.join}]
      [#{VIDEO_DIMENSIONS.join}]
      [#{VIDEO_PLAYBACK_CHANNELS.join}]$
    /x
  end

  def video_f007_error?(field)
    !ideal_video_f007.match?(field)
  end

  def unspec_f007_error?(field)
    regex = /
              ^[#{UNSPECIFIED_MATERIAL_DESIGNATION.join}]$
            /x
    !regex.match?(field)
  end

  def f007_rec_type_to_error_method_name
    { 'a' => 'map_f007_error?', 'c' => 'elec_f007_error?',
      'd' => 'globe_f007_error?', 'f' => 'tactile_f007_error?',
      'g' => 'proj_graphic_f007_error?', 'h' => 'microform_f007_error?',
      'k' => 'nonproj_graphic_f007_error?', 'm' => 'motion_pict_f007_error?',
      'o' => 'kit_mus_f007_error?', 'q' => 'kit_mus_f007_error?',
      'r' => 'remote_f007_error?', 's' => 'sound_recording_f007_error?',
      't' => 'text_f007_error?', 'v' => 'video_f007_error?',
      'z' => 'unspec_f007_error?' }
  end

  def specific_f007_error?(rec_type:, specific_f007:)
    error_method_name = f007_rec_type_to_error_method_name[rec_type]
    if error_method_name
      send(error_method_name, specific_f007)
    else
      true
    end
  end

  def bad_f007?(record)
    fields = record.fields('007')
    return false if fields.empty?

    fields.each do |field|
      rec_type = field.value[0]
      specific_f007 = field.value[1..]
      return true if specific_f007_error?(rec_type: rec_type, specific_f007: specific_f007)
    end
    false
  end

  def f008_record_type_to_error_method_name
    {
      'book' => 'book_f008_error?',
      'computer_file' => 'comp_f008_error?',
      'map' => 'map_f008_error?',
      'music' => 'music_f008_error?',
      'continuing_resource' => 'continuing_resource_f008_error?',
      'visual' => 'visual_f008_error?',
      'mixed' => 'mix_mat_f008_error?'
    }
  end

  def specific_f008_error?(record_type:, specific_f008:)
    error_method_name = f008_record_type_to_error_method_name[record_type]
    if error_method_name
      send(error_method_name, specific_f008)
    else
      true
    end
  end

  def f008_errors(record)
    field = record['008'].value
    return { valid: false, errors: ['Invalid 008 length'] } if field.length != 40

    errors = []
    errors << 'Invalid value in global 008 (positions 0-17, 35-39)' if global_f008_error?(field)
    if specific_f008_error?(record_type: record_type(record.leader[6..7]), specific_f008: field[18..34])
      errors << 'Invalid value in the specific 008 (positions 18-34)'
    end
    { valid: errors.empty?, errors: errors }
  end

  def f007_rec_type_to_fix_method_name
    {
      'a' => 'fix_map_f007', 'c' => 'fix_electronic_f007',
      'd' => 'fix_globe_f007', 'f' => 'fix_tactile_f007',
      'g' => 'fix_proj_f007', 'h' => 'fix_microform_f007',
      'k' => 'fix_nonproj_f007', 'm' => 'fix_motion_pic_f007',
      'o' => 'fix_kit_f007', 'q' => 'fix_notated_mus_f007',
      'r' => 'fix_remote_f007', 's' => 'fix_sound_rec_f007',
      't' => 'fix_text_f007', 'v' => 'fix_video_f007',
      'z' => 'fix_unspec_f007'
    }
  end

  ### Replace obsolete values with current values when possible
  def fix_f007(record)
    record.fields('007').each do |field|
      rec_type = field.value[0]
      method_name = f007_rec_type_to_fix_method_name[rec_type]
      next unless method_name

      fixed_f007 = rec_type.dup
      fixed_f007 << send(method_name, field.value[1..])
      record.fields[record.fields.index(field)] = MARC::ControlField.new('007', fixed_f007)
    end
    record
  end

  def fix_map_f007(specific_f007)
    return specific_f007 unless specific_f007.size == 7

    [
      specific_f007[0], # material designation
      ' ', # undefined
      specific_f007[2].gsub('b', 'c'), # color
      specific_f007[3].gsub(/[^a-gijlnp-z|]/, 'u'), # physical medium
      specific_f007[4].gsub(/[^fnuz|]/, 'u'), # type of reproduction
      specific_f007[5].gsub(/[^abcduz|]/, 'u'), # reproduction details
      specific_f007[6].gsub('u', '|') # positive aspect
    ].join
  end

  def fix_electronic_bit_depth(bit_depth)
    return bit_depth if %w[mmm nnn --- |||].include?(bit_depth)

    bit_depth =~ /^[0-9]{3}$/ ? bit_depth : '---'
  end

  def sanitize_invalid_value(character, allowed_regex)
    if character.match?(allowed_regex)
      character
    else
      'u'
    end
  end

  def allowed_electronic_f007_values
    {
      0 => /[a-fhjkmorsuz|]/, 2 => /[abcghmnuz|]/,
      3 => /[aegijnouvz|]/, 4 => /[ au|]/,
      8 => /[amu|]/, 9 => /[anpu|]/,
      10 => /[abcdmnu|]/, 11 => /[abdmu|]/,
      12 => /[anpru|]/
    }
  end

  # See https://loc.gov/marc/bibliographic/bd007c.html for descriptions of the positions
  def fix_electronic_f007(specific_f007)
    return specific_f007 unless specific_f007.length > 4

    chars = specific_f007.chars
    chars.each_with_index.map do |character, index|
      if (5..7).cover?(index)
        index == 5 ? fix_electronic_bit_depth(chars[5..7].join) : ''
      else
        index == 1 ? ' ' : sanitize_invalid_value(character, allowed_electronic_f007_values[index])
      end
    end.join
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
      writing_chars = writing.chars.grep(/[a-emnuz]/).sort.join
      writing = writing_chars.ljust(2)
    end
    contraction = specific_f007[4]
    contraction = contraction.gsub(/[^abmnuz|]/, 'u')
    music = specific_f007[5..7]
    unless music == '|||'
      music_chars = music.chars.grep(/[a-lnuz]/).sort.join
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
      reduction_nums = reduction_ratio.chars.grep(/[0-9]/).join
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
    data_type = 'uu' unless (REMOTE_DATA_TYPES + ['||']).include? data_type
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
    contents_values = contents.chars.select { |code| (BOOK_CONTENTS - [' ']).include?(code) }.sort.join
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
      illus_chars = illus.chars.select { |c| %w[a b c d e f g h i j k l m o p].include? c }.sort.join
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
      relief_chars = relief.chars.select { |c| %w[a b c d e f g i j k m z].include? c }.sort.join
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
      format_chars = format.chars.select { |c| %w[e j k l n o p r z].include? c }.sort.join
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
      accompanying_chars = accompanying.chars.select { |c| %w[a b c d e f g h i k r s z].include? c }.sort.join
      accompanying = accompanying_chars.ljust(6)
    end
    fixed_field << accompanying
    unless ['||', '  '].include? lit_text
      lit_text_chars = lit_text.chars.select do |c|
        %w[a b c d e f g h i j k l m n o p r s t z].include? c
      end.sort.join
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
