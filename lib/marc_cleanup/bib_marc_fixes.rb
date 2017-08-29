module MarcCleanup
  def controlcharfix(record)
    char_regex = /[#{END_OF_FIELD}#{END_OF_RECORD}#{SUBFIELD_INDICATOR}\n\r]/
    record.force_encoding('binary')
    fixed_record = ''
    leader = record.slice(0..LEADER_LENGTH - 1)
    fixed_record << leader
    base_address = leader[12..16].to_i
    directory = record[LEADER_LENGTH..base_address - 2]
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
      field_data = mba[field_start..field_end].pack('c*')
      field_data.force_encoding('UTF-8')
      if tag =~ /00[1-9]/
        field_data.gsub!(char_regex, '')
        fixed_field << field_data
      else
        field_data.gsub!(/[#{END_OF_FIELD}]/, '')
        subfields = field_data.split(SUBFIELD_INDICATOR)
        indicators = subfields.shift
        fixed_field << indicators
        subfields.each do |subfield|
          next if subfield.nil?
          fixed_subfield = subfield.gsub(char_regex, '')
          fixed_field << SUBFIELD_INDICATOR
          fixed_field << fixed_subfield
        end
      end
      fixed_field << END_OF_FIELD
      fixed_record << fixed_field
      field_length = fixed_field.respond_to?(:bytesize) ? fixed_field.bytesize : fixed_field.length
      new_directory << format('%03s', tag)
      new_directory << format('%04i', field_length)
      new_directory << format('%05i', new_offset)
      new_offset += field_length
    end
    fixed_record << END_OF_RECORD
    fixed_length = fixed_record.respond_to?(:bytesize) ? fixed_record.bytesize : fixed_record.length
    fixed_record[0..4] = format('%05i', fixed_length)
    fixed_record[LEADER_LENGTH..base_address - 2] = new_directory
    fixed_record
  end
end
