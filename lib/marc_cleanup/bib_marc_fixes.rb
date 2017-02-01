module Marc_Cleanup

  def leaderfix(record)
    leader = record[0..23].scrub
    to_end = record[24..-1].scrub
    if leader.match(/[0-9]{5}[acdnp][acdefgijkmoprt][abcdims][\sa][\sa]22[0-9]{5}[12345678uzIJKLM\s][aciu\s][abcr\s]4500/) == nil
      length = leader[0, 5]
      if leader.match(/(^.{5})([acdnp])/) == nil
        status = 'n'
      else
        status = leader[5]
      end
      record_type = leader[6]
      bib_level = leader[7]
      if leader.match(/(^.{8})([a ])/) == nil
        control = ' '
      else
        control = leader[8]
      end
      character_scheme = leader[9]
      indsub = '22'
      base_addr = leader[12, 5]
      if leader.match(/(^.{17})([1-8uzIJKLM ])/) == nil
        enc_level = 'u'
      else
        enc_level = leader[17]
      end
      if leader.match(/(^.{18})([aciu ])/) == nil
        cat_form = 'u'
      else
        cat_form = leader[18]
      end
      if leader.match(/(^.{19})([abcr ])/) == nil
        multipart = ' '
      else
        multipart = leader[19]
      end
      final4 = '4500'
      fixed_leader = [length, status, record_type, bib_level, control, character_scheme, indsub, base_addr, enc_level, cat_form, multipart, final4].join
      fixed_record = [fixed_leader, to_end].join
    else
      record
    end
  end

  def tab_fix(record)
    record.gsub(/\x09/, ' ')
  end

  def composed_chars(record)
    record.force_encoding("binary")
    fixed_record = ''
    leader = record.slice(0..LEADER_LENGTH-1)
    fixed_record << leader
    base_address = leader[12..16].to_i
    directory = record[LEADER_LENGTH..base_address-2]
    num_fields = directory.length / DIRECTORY_ENTRY_LENGTH
    marc_field_data = record[base_address..-1]
    marc_field_data.force_encoding("binary")
    fixed_record << directory
    fixed_record << END_OF_FIELD
    new_directory = ''
    all_fields = marc_field_data.split(END_OF_FIELD)
    new_offset = 0
    0.upto(num_fields - 1) do |field_num|
      entry_start = field_num * DIRECTORY_ENTRY_LENGTH
      entry_end = entry_start + DIRECTORY_ENTRY_LENGTH
      entry = directory[entry_start..entry_end]
      tag = entry[0..2]
      field_data = all_fields.shift()
      field_data.delete!(END_OF_FIELD)
      if tag =~ /00[1-9]/
        field_data.force_encoding("UTF-8")
        field_data << END_OF_FIELD
        fixed_record << field_data
        field_length = (field_data.respond_to?(:bytesize) ?
          field_data.bytesize() :
          field_data.length())
        new_directory << sprintf("%03s", tag)
        new_directory << sprintf("%04i", field_length)
        new_directory << sprintf("%05i", new_offset)
        new_offset += field_length
      else
        fixed_field = ''
        subfields = field_data.split(SUBFIELD_INDICATOR)
        indicators = subfields.shift()
        fixed_field << indicators
        subfields.each() do |subfield|
          subfield = subfield.force_encoding("UTF-8")
          subfield.unicode_normalize!(:nfd)
          fixed_field << SUBFIELD_INDICATOR
          fixed_field << subfield
        end
        fixed_field << END_OF_FIELD
        fixed_record << fixed_field
        field_length = (fixed_field.respond_to?(:bytesize) ?
          fixed_field.bytesize() :
          fixed_field.length())
        new_directory << sprintf("%03s", tag)
        new_directory << sprintf("%04i", field_length)
        new_directory << sprintf("%05i", new_offset)
        new_offset += field_length
      end
    end
    fixed_record << END_OF_RECORD
    fixed_length = (fixed_record.respond_to?(:bytesize) ?
            fixed_record.bytesize() :
            field_record.length())
    fixed_record[0..4] = sprintf("%05i", fixed_length)
    fixed_record[LEADER_LENGTH..base_address-2] = new_directory
    fixed_record
  end    

  def extra_space_fix(record)
    record.force_encoding("binary") if record.respond_to?(:force_encoding)
    fixed_record = ''
    leader = record.slice(0..23)
    fixed_record << leader
    base_address = leader[12..16].to_i
    directory = record[LEADER_LENGTH..base_address-2]
    fixed_record << directory
    fixed_record << END_OF_FIELD
    new_directory = ''
    num_fields = directory.length / DIRECTORY_ENTRY_LENGTH
    mba = record.bytes.to_a
    new_offset = 0
    0.upto(num_fields - 1) do |field_num|
      entry_start = field_num * DIRECTORY_ENTRY_LENGTH
      entry_end = entry_start + DIRECTORY_ENTRY_LENGTH
      entry = directory[entry_start..entry_end]
      tag = entry[0..2]
      length = entry[3..6].to_i
      offset = entry[7..11].to_i
      fixed_field = ''
      field_start = base_address + offset
      field_end = field_start + length - 1
      field_data = mba[field_start..field_end].pack("c*")
      if tag =~ /00[1-9]/
        field_data = field_data.force_encoding("UTF-8")
        fixed_record << field_data
        field_length = (field_data.respond_to?(:bytesize) ?
          field_data.bytesize() :
          field_data.length())
        new_directory << sprintf("%03s", tag)
        new_directory << sprintf("%04i", field_length)
        new_directory << sprintf("%05i", new_offset)
        new_offset += field_length
      else
        field_data = field_data.force_encoding("UTF-8")
        indicators = field_data.slice!(0..2).gsub(/#{SUBFIELD_INDICATOR}/, '')
        fixed_field << indicators
        field_data.delete!(END_OF_FIELD)
        subfields = field_data.split(SUBFIELD_INDICATOR)
        if tag =~ /[1-469]..|0[2-9].|01[1-9]|7[0-5].|5[0-24-9].|53[0-24-9]/
          subfields.each do |subfield|
            subfield.gsub!(/([[:blank:]]){2,}/, '\1')
            subfield.gsub!(/[[:blank:]]+$/, '')
              fixed_field << SUBFIELD_INDICATOR
              fixed_field << subfield
          end
          fixed_field << END_OF_FIELD
          fixed_record << fixed_field
          field_length = (fixed_field.respond_to?(:bytesize) ?
            fixed_field.bytesize() :
            fixed_field.length())
          new_directory << sprintf("%03s", tag)
          new_directory << sprintf("%04i", field_length)
          new_directory << sprintf("%05i", new_offset)
          new_offset += field_length
        elsif tag == '533'
          subfields.each do |subfield|
            subfield_code = subfield[0]
            if subfield_code =~ /[^7]/
              subfield.gsub!(/([[:blank:]]){2,}/, '\1')
              subfield.gsub!(/[[:blank:]]+$/, '')
              fixed_field << SUBFIELD_INDICATOR
              fixed_field << subfield
            else
              subfield.gsub!(/[[:blank:]]+$/, '')
              fixed_field << SUBFIELD_INDICATOR
              fixed_field << subfield
            end
          end
          fixed_field << END_OF_FIELD
          fixed_record << fixed_field
          field_length = (fixed_field.respond_to?(:bytesize) ?
            fixed_field.bytesize() :
            fixed_field.length())
          new_directory << sprintf("%03s", tag)
          new_directory << sprintf("%04i", field_length)
          new_directory << sprintf("%05i", new_offset)
          new_offset += field_length
        elsif tag =~ /7[6-8]./
          subfields.each do |subfield|
            subfield_code = subfield[0]
            if subfield_code =~ /[a-v3-8]/
              subfield.gsub!(/([[:blank:]]){2,}/, '\1')
              subfield.gsub!(/[[:blank:]]+$/, '')
              fixed_field << SUBFIELD_INDICATOR
              fixed_field << subfield
            else
              subfield.gsub!(/[[:blank:]]+$/, '')
              fixed_field << SUBFIELD_INDICATOR
              fixed_field << subfield
            end
          end
          fixed_field << END_OF_FIELD
          fixed_record << fixed_field
          field_length = (fixed_field.respond_to?(:bytesize) ?
            fixed_field.bytesize() :
            fixed_field.length())
          new_directory << sprintf("%03s", tag)
          new_directory << sprintf("%04i", field_length)
          new_directory << sprintf("%05i", new_offset)
          new_offset += field_length
        elsif tag =~ /8../
          subfields.each do |subfield|
            subfield_code = subfield[0]
            if subfield_code =~ /[^w7]/
              subfield.gsub!(/([[:blank:]]){2,}/, '\1')
              subfield.gsub!(/[[:blank:]]+$/, '')
              fixed_field << SUBFIELD_INDICATOR
              fixed_field << subfield
            else
              subfield.gsub!(/[[:blank:]]+$/, '')
              fixed_field << SUBFIELD_INDICATOR
              fixed_field << subfield
            end
          end
          fixed_field << END_OF_FIELD
          fixed_record << fixed_field
          field_length = (fixed_field.respond_to?(:bytesize) ?
            fixed_field.bytesize() :
            fixed_field.length())
          new_directory << sprintf("%03s", tag)
          new_directory << sprintf("%04i", field_length)
          new_directory << sprintf("%05i", new_offset)
          new_offset += field_length
        else
          subfields.each do |subfield|
              fixed_field << SUBFIELD_INDICATOR
              fixed_field << subfield
          end
          fixed_field << END_OF_FIELD
          fixed_record << fixed_field
          field_length = (fixed_field.respond_to?(:bytesize) ?
            fixed_field.bytesize() :
            fixed_field.length())
          new_directory << sprintf("%03s", tag)
          new_directory << sprintf("%04i", field_length)
          new_directory << sprintf("%05i", new_offset)
          new_offset += field_length
        end
      end
    end
    fixed_record << END_OF_RECORD
    fixed_length = (fixed_record.respond_to?(:bytesize) ?
            fixed_record.bytesize() :
            field_record.length())
    fixed_record[0..4] = sprintf("%05i", fixed_length)
    fixed_record[LEADER_LENGTH..base_address-2] = new_directory
    fixed_record
  end
end
