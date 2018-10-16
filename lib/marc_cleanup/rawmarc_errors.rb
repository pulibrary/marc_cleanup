module MarcCleanup
  def directory_errors?(record)
    record.force_encoding('binary')
    record.scrub =~ /^.{24}(.{12})+[\x1e]/ ? false : true
  end

  def controlchar_errors?(record)
    control_regex = /[#{END_OF_RECORD}#{SUBFIELD_INDICATOR}\n\r]/
    record.force_encoding('binary')
    leader = record.slice(0..LEADER_LENGTH - 1)
    base_address = leader[12..16].to_i
    directory = record[LEADER_LENGTH..base_address - 2]
    num_fields = directory.length / DIRECTORY_ENTRY_LENGTH
    mba = record.bytes.to_a
    0.upto(num_fields - 1) do |field_num|
      entry_start = field_num * DIRECTORY_ENTRY_LENGTH
      entry_end = entry_start + DIRECTORY_ENTRY_LENGTH
      entry = directory[entry_start..entry_end]
      next if entry =~ /[^0-9]/
      tag = entry[0..2]
      length = entry[3..6].to_i
      offset = entry[7..11].to_i
      field_start = base_address + offset + 1
      field_end = field_start + length - 2
      next unless mba[field_start..field_end]
      field_data = mba[field_start..field_end].pack('c*')
      field_data.force_encoding('UTF-8')
      field_data.scrub!
      if tag =~ /00[1-9]/
        return true if field_data =~ control_regex
      else
        field_data.gsub!(/[#{END_OF_FIELD}]/, '')
        subfields = field_data.split(SUBFIELD_INDICATOR)
        subfields.shift
        subfields.each do |subfield|
          return true if subfield =~ control_regex
        end
      end
    end
    false
  end
end
