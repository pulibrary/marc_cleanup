module Marc_Cleanup

  def leader_errors(record)
    leader = record[0..23].scrub
    if leader.match(/[0-9]{5}[acdnp][acdefgijkmoprt][abcdims][\sa][\sa]22[0-9]{5}[12345678uzIJKLM\s][aciu\s][abcr\s]4500/) == nil
       record
    end
  end

  def directory_errors(record)
    if record.scrub.match(/^.{24}([0-9]{12})+[\x1e]/) == nil
      record
    end
  end

  def invalid_indicators(record)
    if record.match(/\x1e(?![0-9 ]{2})\x1f/)
      record
    end
  end

  def invalid_subfield_code(record)
    if record.match(/\x1f[^0-9a-z]/)
      record
    end
  end

  def tab_char(record)
    if record.match(/\x09/)
      record
    end
  end

  def invalid_xml_chars(record)
    if record.match(/[\u0000-\u0008\u000B\u000C\u000E-\u001C\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF]/)
      record.gsub!(/([\u0000-\u0008\u000B\u000C\u000E-\u001C\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF])/, '░\1░')
    end
  end

  def combining_chars(record)
    if record.match(/[^\p{L}\p{M}]\p{M}+/)
      record.gsub!(/([^\p{L}\p{M}]\p{M}+)/, '░\1░')
    end
  end

  def invalid_chars(record)
    good_chars = CHARSET.keys
    add_to_file = false
    bad_record = ""
    record.each_char do |c|
      if good_chars.include?(c.ord)
        bad_record << c
      else
        bad_record << "░#{c}░"
        add_to_file = true
      end
    end
    if add_to_file
      bad_record
    else
      add_to_file
    end
  end

  def empty_subfield(record)
    if record.match(/\x1f[ ]*[\x1e\x1f]/)
      record
    end
  end

  def no_245(record)
    leader = record.slice(0..23)
    base_address = leader[12..16].to_i
    directory = record[LEADER_LENGTH..base_address-1]
    if directory.match(/(.{12})*(245[0-9]{9})/)
      bad_record = nil
    else
      record
    end
  end

  def relator_chars(record)
    relator_incorrect = false
    leader = record.slice(0..23)
    base_address = leader[12..16].to_i
    directory = record[LEADER_LENGTH..base_address-2]
    num_fields = directory.length / DIRECTORY_ENTRY_LENGTH
    mba = record.bytes.to_a
    0.upto(num_fields - 1) do |field_num|
      entry_start = field_num * DIRECTORY_ENTRY_LENGTH
      entry_end = entry_start + DIRECTORY_ENTRY_LENGTH
      entry = directory[entry_start..entry_end]
      tag = entry[0..2]
      if tag =~ /[17][01]0/
        field_data = ''
        length = entry[3..6].to_i
        offset = entry[7..11].to_i
        field_start = base_address + offset
        field_end = field_start + length - 1
        field_data = mba[field_start..field_end].pack("c*")
        field_data.slice!(0..2)
        field_data.delete!(END_OF_FIELD)
        subfields = field_data.split(SUBFIELD_INDICATOR)
        next if subfields.length() < 2
        subfields.each do |subfield|
          if subfield.match(/^e.*[^a-z, \.\x1f]/)
            relator_incorrect = true
          end
        end
      elsif tag =~ /[17]11/
        field_data = ''
        length = entry[3..6].to_i
        offset = entry[7..11].to_i
        field_start = base_address + offset
        field_end = field_start + length - 1
        field_data = mba[field_start..field_end].pack("c*")
        field_data.slice!(0..2)
        field_data.delete!(END_OF_FIELD)
        subfields = field_data.split(SUBFIELD_INDICATOR)
        next if subfields.length() < 2
        subfields.each do |subfield|
          if subfield.match(/^j.*[^a-z ,\.\x1f]/)
            relator_incorrect = true
          end
        end
      end
    end
    if relator_incorrect == true
      record
    else
      relator_incorrect
    end
  end

  def x00_subfq(record)
    subfq_incorrect = false
    leader = record.slice(0..23)
    base_address = leader[12..16].to_i
    directory = record[LEADER_LENGTH..base_address-2]
    num_fields = directory.length / DIRECTORY_ENTRY_LENGTH
    mba = record.bytes.to_a
    0.upto(num_fields - 1) do |field_num|
      entry_start = field_num * DIRECTORY_ENTRY_LENGTH
      entry_end = entry_start + DIRECTORY_ENTRY_LENGTH
      entry = directory[entry_start..entry_end]
      tag = entry[0..2]
      if tag =~ /[167]00/
        field_data = ''
        length = entry[3..6].to_i
        offset = entry[7..11].to_i
        field_start = base_address + offset
        field_end = field_start + length - 1
        field_data = mba[field_start..field_end].pack("c*")
        field_data.slice!(0..2)
        field_data.delete!(END_OF_FIELD)
        subfields = field_data.split(SUBFIELD_INDICATOR)
        next if subfields.length() < 2
        subfields.each do |subfield|
          if subfield.match(/^q[^\(][^\)]*\)/)
            subfq_incorrect = true
          end
        end
      end
    end
    if subfq_incorrect == true
      record
    else
      subfq_incorrect
    end
  end

  def no_comma_x00(record)
    no_comma_incorrect = false
    leader = record.slice(0..23)
    base_address = leader[12..16].to_i
    directory = record[LEADER_LENGTH..base_address-2]
    num_fields = directory.length / DIRECTORY_ENTRY_LENGTH
    mba = record.bytes.to_a
    0.upto(num_fields - 1) do |field_num|
      entry_start = field_num * DIRECTORY_ENTRY_LENGTH
      entry_end = entry_start + DIRECTORY_ENTRY_LENGTH
      entry = directory[entry_start..entry_end]
      tag = entry[0..2]
      if tag =~ /[167]00/
        field_data = ''
        length = entry[3..6].to_i
        offset = entry[7..11].to_i
        field_start = base_address + offset
        field_end = field_start + length - 1
        field_data = mba[field_start..field_end].pack("c*")
        field_data.slice!(0..2)
        field_data.delete!(END_OF_FIELD)
        subfields = field_data.split(SUBFIELD_INDICATOR)
        subfield_string = ''
        subfields.each do |data|
          subfield_string << data[0]
        end
        subfx_d_index = subfield_string.index(/.d/)
        if subfx_d_index
          if subfields[subfx_d_index] =~ /[^,]$/
            no_comma_incorrect = true
          end
        end
      end
    end
    if no_comma_incorrect == true
      record
    else
      no_comma_incorrect
    end
  end

  def relator_comma(record)
    relator_comma_incorrect = false
    leader = record.slice(0..23)
    base_address = leader[12..16].to_i
    directory = record[LEADER_LENGTH..base_address-2]
    num_fields = directory.length / DIRECTORY_ENTRY_LENGTH
    mba = record.bytes.to_a
    0.upto(num_fields - 1) do |field_num|
      entry_start = field_num * DIRECTORY_ENTRY_LENGTH
      entry_end = entry_start + DIRECTORY_ENTRY_LENGTH
      entry = directory[entry_start..entry_end]
      tag = entry[0..2]
      if tag =~ /[17][01]0/
        field_data = ''
        length = entry[3..6].to_i
        offset = entry[7..11].to_i
        field_start = base_address + offset
        field_end = field_start + length - 1
        field_data = mba[field_start..field_end].pack("c*")
        field_data.slice!(0..2)
        field_data.delete!(END_OF_FIELD)
        subfields = field_data.split(SUBFIELD_INDICATOR)
        subfield_string = ''
        subfields.each do |data|
          subfield_string << data[0]
        end
        subfx_e_index = subfield_string.index(/.e/)
        if subfx_e_index
          if subfields[subfx_e_index] =~ /[^,\-]$/
            relator_comma_incorrect = true
          end
        end
      elsif tag =~ /[17]11/
        field_data = ''
        length = entry[3..6].to_i
        offset = entry[7..11].to_i
        field_start = base_address + offset
        field_end = field_start + length - 1
        field_data = mba[field_start..field_end].pack("c*")
        field_data.slice!(0..2)
        field_data.delete!(END_OF_FIELD)
        subfields = field_data.split(SUBFIELD_INDICATOR)
        subfield_string = ''
        subfields.each do |data|
          subfield_string << data[0]
        end
        subfx_j_index = subfield_string.index(/.j/)
        if subfx_j_index
          if subfields[subfx_j_index] =~ /[^,\-]$/
            relator_comma_incorrect = true
          end
        end
      end
    end
    if relator_comma_incorrect == true
      record
    else
      relator_comma_incorrect
    end
  end

  def heading_end_punct(record)
    end_punct_incorrect = false
    leader = record.slice(0..23)
    base_address = leader[12..16].to_i
    directory = record[LEADER_LENGTH..base_address-2]
    num_fields = directory.length / DIRECTORY_ENTRY_LENGTH
    mba = record.bytes.to_a
    0.upto(num_fields - 1) do |field_num|
      entry_start = field_num * DIRECTORY_ENTRY_LENGTH
      entry_end = entry_start + DIRECTORY_ENTRY_LENGTH
      entry = directory[entry_start..entry_end]
      tag = entry[0..2]
      if tag =~ /[167][0-5].|8[013]./
        field_data = ''
        length = entry[3..6].to_i
        offset = entry[7..11].to_i
        field_start = base_address + offset
        field_end = field_start + length - 1
        field_data = mba[field_start..field_end].pack("c*")
        field_data.slice!(0..2)
        field_data.delete!(END_OF_FIELD)
        subfields = field_data.split(SUBFIELD_INDICATOR)
        subfield_codes = subfields.each { |data| data[0] }.join('')
        last_heading_subfield_index = subfield_codes.index(/[a-vx-z8][^a-vx-z8]*$/)
        if last_heading_subfield_index
          if subfields[last_heading_subfield_index] =~ /.*[^\).\?\-]$/
            end_punct_incorrect = true
          end
        end
      end
    end
    if end_punct_incorrect == true
      record
    else
      end_punct_incorrect
    end
  end
        
  def extra_spaces(record)
    extra_space = false
    leader = record.slice(0..23)
    base_address = leader[12..16].to_i
    directory = record[LEADER_LENGTH..base_address-2]
    num_fields = directory.length / DIRECTORY_ENTRY_LENGTH
    mba = record.bytes.to_a
    0.upto(num_fields - 1) do |field_num|
      entry_start = field_num * DIRECTORY_ENTRY_LENGTH
      entry_end = entry_start + DIRECTORY_ENTRY_LENGTH
      entry = directory[entry_start..entry_end]
      tag = entry[0..2]
      field_data = ''
      length = entry[3..6].to_i
      offset = entry[7..11].to_i
      field_start = base_address + offset
      field_end = field_start + length - 1
      field_data = mba[field_start..field_end].pack("c*")
      field_data.slice!(0..2)
      field_data.delete!(END_OF_FIELD)
      subfields = field_data.split(SUBFIELD_INDICATOR)
      if tag =~ /[1-469]..|01[1-9]|0[2-9].|7[0-5].|5[0-24-9].|53[0-24-9]/
        next if subfields.length() < 2
        subfields.each do |subfield|
          if subfield.match(/[\s]{2,}/)
            extra_space = true
          end
        end
      end
      if tag == '533'
        next if subfields.length() < 2
        subfields.each do |subfield|
          subfield_code = subfield[0]
          if subfield_code =~ /[^7]/
            if subfield.match(/[\s]{2,}/)
              extra_space = true
            end
          end
        end
      end
      if tag =~ /7[6-8]./
        next if subfields.length() < 2
        subfields.each do |subfield|
          subfield_code = subfield[0]
          if subfield_code =~ /[a-v3-8]/
            if subfield.match(/[\s]{2,}/)
              extra_space = true
            end
          end
        end
      end
      if tag =~ /8../
        next if subfields.length() < 2
        subfields.each do |subfield|
          subfield_code = subfield[0]
          if subfield_code =~ /[^w7]/
            if subfield.match(/[\s]{2,}/)
              extra_space = true
            end
          end
        end
      end
      if tag =~ /[1-9]../
        next if subfields.length() < 2
        subfields.each do |subfield|
          if subfield.match(/[\s]+$/)
            extra_space = true
          end
        end
      end
    end
    if extra_space == true
      record
    else
      extra_space
    end
  end

  def subfield_count
    Dir.glob("#{ROOT_DIR}/marc/*.mrc") do |file|
      File.open("#{file}", 'r') do |input|
        puts "Processing #{file}..."
        controlfield_tag_array = []
        datafield_tag_array = []
        subfield_array = []
        records = input.gets.scrub(' ').split(END_OF_RECORD)
        records.each do |record|
          leader = record.slice(0..23)
          base_address = leader[12..16].to_i
          directory = record[LEADER_LENGTH..base_address-1]
          num_fields = directory.length / DIRECTORY_ENTRY_LENGTH
          mba = record.bytes.to_a
          0.upto(num_fields - 1) do |field_num|
            entry_start = field_num * DIRECTORY_ENTRY_LENGTH
            entry_end = entry_start + DIRECTORY_ENTRY_LENGTH
            entry = directory[entry_start..entry_end]
            tag = entry[0..2]
            field_data = ''
            length = entry[3..6].to_i
            offset = entry[7..11].to_i
            field_start = base_address + offset
            field_end = field_start + length - 1
            field_data = mba[field_start..field_end].pack("c*")
            field_data.delete!(END_OF_FIELD)
            if MARC::ControlField.control_tag?(tag)
              controlfield_tag_array.push(tag)
            else
              datafield_tag_array.push(tag)
              field_data.slice!(0..2)
              subfields = field_data.split(SUBFIELD_INDICATOR)
              next if subfields.length() < 2
              subfields.each do |data|
                subfield_array.push(tag + '|' + data[0].to_s)
              end
            end
          end
        end
        controlfield_tag_tally = controlfield_tag_array.sort.group_by { |w| w }.map {|k,v| [k, v.length]}
        datafield_tag_tally = datafield_tag_array.sort.group_by { |w| w }.map {|k,v| [k, v.length]}
        subfield_tally = subfield_array.sort.group_by { |w| w }.map {|k,v| [k, v.length]}
        File.open("#{ROOT_DIR}/logs/field_counts.txt", 'a') do |output|
          output.puts("File: #{file}")
          controlfield_tag_tally.each do |row|
            output.puts(row[0] + "\t" + row[1].to_s)
          end
          datafield_tag_tally.each do |row|
            output.puts(row[0] + "\t" + row[1].to_s)
          end
        end
        File.open("#{ROOT_DIR}/logs/subfield_counts.txt", 'a') do |output|
          output.puts("File: #{file}")
          subfield_tally.each do |row|
            output.puts(row[0] + "\t" + row[1].to_s)
          end
        end
      end
    end
  end
end
