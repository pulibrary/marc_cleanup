module Marc_Cleanup

  def controlcharfix(record)
    record.force_encoding("binary")
    fixed_record = ''
    leader = record.slice(0..LEADER_LENGTH-1)
    fixed_record << leader
    base_address = leader[12..16].to_i
    directory = record[LEADER_LENGTH..base_address-2]
    num_fields = directory.length / DIRECTORY_ENTRY_LENGTH
    mba = record.bytes.to_a
    fixed_record << directory
    fixed_record << END_OF_FIELD
    new_directory = ''
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
      field_data.force_encoding("UTF-8")
      if tag =~ /00[1-9]/
        field_data.gsub!(/[#{END_OF_FIELD}#{END_OF_RECORD}#{SUBFIELD_INDICATOR}\n\r]/, '')
        fixed_field << field_data
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
        field_data.gsub!(/[#{END_OF_FIELD}]/, '')
        subfields = field_data.split(SUBFIELD_INDICATOR)
        indicators = subfields.shift()
        fixed_field << indicators
        subfields.each() do |subfield|
          unless subfield.nil?
            fixed_subfield = subfield.gsub(/[#{END_OF_FIELD}#{END_OF_RECORD}#{SUBFIELD_INDICATOR}\n\r]/, '')
            fixed_field << SUBFIELD_INDICATOR
            fixed_field << fixed_subfield
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
      end
    end
    fixed_record << END_OF_RECORD
    fixed_length = (fixed_record.respond_to?(:bytesize) ?
            fixed_record.bytesize() :
            fixed_record.length())
    fixed_record[0..4] = sprintf("%05i", fixed_length)
    fixed_record[LEADER_LENGTH..base_address-2] = new_directory
    fixed_record
  end

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

  def tab_newline_fix(record)
    record.gsub(/[\x09\n\r]/, ' ')
  end

  def composed_chars_latin_fix(record)
    record.force_encoding("binary")
    fixed_record = ''
    leader = record.slice(0..LEADER_LENGTH-1)
    fixed_record << leader
    base_address = leader[12..16].to_i
    directory = record[LEADER_LENGTH..base_address-2]
    num_fields = directory.length / DIRECTORY_ENTRY_LENGTH
    marc_field_data = record[base_address..-1]
    fixed_record << directory
    fixed_record << END_OF_FIELD
    new_directory = ''
    all_fields = marc_field_data.split(END_OF_FIELD)
    all_fields.pop
    new_offset = 0
    0.upto(num_fields - 1) do |field_num|
      entry_start = field_num * DIRECTORY_ENTRY_LENGTH
      entry_end = entry_start - 1 + DIRECTORY_ENTRY_LENGTH
      entry = directory[entry_start..entry_end]
      tag = entry[0..2]
      field_data = all_fields.shift()
      if tag =~ /00[1-9]/
        field_data.force_encoding("UTF-8")
        fixed_field = ''
        fixed_field << field_data
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
        fixed_field = ''
        subfields = field_data.split(SUBFIELD_INDICATOR)
        indicators = subfields.shift()
        fixed_field << indicators
        subfields.each do |subfield|
          subfield = subfield.force_encoding("UTF-8")
          fixed_subfield = ''
          subfield.each_codepoint do |c|
            if c < 1570 || (7680..10792).include?(c)
              fixed_subfield << c.chr(Encoding::UTF_8).unicode_normalize(:nfd)
            else
              fixed_subfield << c.chr(Encoding::UTF_8)
            end
          end
          fixed_field << SUBFIELD_INDICATOR
          fixed_field << fixed_subfield
        end
        fixed_field << END_OF_FIELD
        fixed_field.force_encoding("UTF-8")
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
            fixed_record.length())
    fixed_record[0..4] = sprintf("%05i", fixed_length)
    fixed_record[LEADER_LENGTH..base_address-2] = new_directory
    fixed_record
  end
  
  def extra_space_fix(record)
    record.force_encoding("binary")
    fixed_record = ''
    leader = record.slice(0..LEADER_LENGTH-1)
    fixed_record << leader
    base_address = leader[12..16].to_i
    directory = record[LEADER_LENGTH..base_address-2]
    num_fields = directory.length / DIRECTORY_ENTRY_LENGTH
    marc_field_data = record[base_address..-1]
    fixed_record << directory
    fixed_record << END_OF_FIELD
    new_directory = ''
    all_fields = marc_field_data.split(END_OF_FIELD)
    all_fields.pop
    new_offset = 0
    0.upto(num_fields - 1) do |field_num|
      entry_start = field_num * DIRECTORY_ENTRY_LENGTH
      entry_end = entry_start - 1 + DIRECTORY_ENTRY_LENGTH
      entry = directory[entry_start..entry_end]
      tag = entry[0..2]
      field_data = all_fields.shift()
      if tag =~ /00[1-9]/
        field_data.force_encoding("UTF-8")
        fixed_field = ''
        fixed_field << field_data
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
        field_data = field_data.force_encoding("UTF-8")
        fixed_field = ''
        subfields = field_data.split(SUBFIELD_INDICATOR)
        indicators = subfields.shift()
        fixed_field << indicators
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
            fixed_record.length())
    fixed_record[0..4] = sprintf("%05i", fixed_length)
    fixed_record[LEADER_LENGTH..base_address-2] = new_directory
    fixed_record
  end

  def empty_subfield_fix(record)
    record.force_encoding("binary")
    fixed_record = ''
    leader = record.slice(0..LEADER_LENGTH-1)
    fixed_record << leader
    base_address = leader[12..16].to_i
    directory = record[LEADER_LENGTH..base_address-2]
    num_fields = directory.length / DIRECTORY_ENTRY_LENGTH
    marc_field_data = record[base_address..-1]
    fixed_record << END_OF_FIELD
    new_directory = ''
    all_fields = marc_field_data.split(END_OF_FIELD)
    all_fields.pop
    new_offset = 0
    0.upto(num_fields - 1) do |field_num|
      entry_start = field_num * DIRECTORY_ENTRY_LENGTH
      entry_end = entry_start - 1 + DIRECTORY_ENTRY_LENGTH
      entry = directory[entry_start..entry_end]
      tag = entry[0..2]
      field_data = all_fields.shift()
      if tag =~ /00[1-9]/
        field_data.force_encoding("UTF-8")
        fixed_field = ''
        fixed_field << field_data
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
        field_data.force_encoding("UTF-8")
        fixed_field = ''
        subfields = field_data.split(SUBFIELD_INDICATOR)
        indicators = subfields.shift()
        fixed_field << indicators
        subfields.each do |subfield|
          if subfield[1..-1]
            fixed_field << SUBFIELD_INDICATOR
            fixed_field << subfield
          end
        end
        unless fixed_field.length < 4
          fixed_field << END_OF_FIELD
          fixed_field.force_encoding("UTF-8")
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
    fixed_record.insert(24, new_directory)
    fixed_length = (fixed_record.respond_to?(:bytesize) ?
      fixed_record.bytesize :
      fixed_record.length)
    fixed_record[0..4] = sprintf("%05i", fixed_length)
    new_base = new_directory.length + LEADER_LENGTH + 1
    fixed_record[12..16] = sprintf("%05i", new_base)
    fixed_record
  end

  def field_delete(tag, record)
    record.force_encoding("binary")
    fixed_record = ''
    leader = record.slice(0..LEADER_LENGTH-1)
    fixed_record << leader
    base_address = leader[12..16].to_i
    directory = record[LEADER_LENGTH..base_address-2]
    num_fields = directory.length / DIRECTORY_ENTRY_LENGTH
    marc_field_data = record[base_address..-1]
    fixed_record << END_OF_FIELD
    new_directory = ''
    all_fields = marc_field_data.split(END_OF_FIELD)
    all_fields.pop
    new_offset = 0
    0.upto(num_fields - 1) do |field_num|
      entry_start = field_num * DIRECTORY_ENTRY_LENGTH
      entry_end = entry_start - 1 + DIRECTORY_ENTRY_LENGTH
      entry = directory[entry_start..entry_end]
      field_tag = entry[0..2]
      field_data = all_fields.shift()
      unless field_tag == tag
        if tag =~ /00[1-9]/
          field_data.force_encoding("UTF-8")
          fixed_field = ''
          fixed_field << field_data
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
        field_data.force_encoding("UTF-8")
        fixed_field = ''
        subfields = field_data.split(SUBFIELD_INDICATOR)
        indicators = subfields.shift()
        fixed_field << indicators
        subfields.each do |subfield|
          subfield_code = subfield[0]
          fixed_field << SUBFIELD_INDICATOR
          fixed_field << subfield
          end
        end
        fixed_field << END_OF_FIELD
        fixed_field.force_encoding("UTF-8")
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
    fixed_record.insert(24, new_directory)
    fixed_length = (fixed_record.respond_to?(:bytesize) ?
      fixed_record.bytesize :
      fixed_record.length)
    fixed_record[0..4] = sprintf("%05i", fixed_length)
    new_base = new_directory.length + LEADER_LENGTH + 1
    fixed_record[12..16] = sprintf("%05i", new_base)
    fixed_record
  end
end
