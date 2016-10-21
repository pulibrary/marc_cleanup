module Marc_Cleanup

  def leader_errors
    Dir.glob("#{ROOT_DIR}/parsed/*.mrc.parsed") do |file|
      File.open("#{file}", 'r') do |input|
        puts "Processing #{file}..."
        File.open("#{ROOT_DIR}/marctofix/leader_errors.mrc", 'a') do |output|
          while line = input.gets
            leader = line[0..23].scrub
            if leader.match(/[0-9]{5}[acdnp][acdefgijkmoprt][abcdims][\sa][\sa]22[0-9]{5}[12345678uzIJKLM\s][aciu\s][abcr\s]4500/) == nil
              output.write(line.chomp)
            end
          end
        end
      end
    end
  end

  def directory_errors
    Dir.glob("#{ROOT_DIR}/parsed/*.mrc.parsed") do |file|
      File.open("#{file}", 'r') do |input|
        puts "Processing #{file}..."
        File.open("#{ROOT_DIR}/marctofix/directory_errors.mrc", 'a') do |output|
          while line = input.gets
            if line.scrub.match(/^.{24}([0-9]{12})+[\x1e]/) == nil
              output.write(line.chomp)
            end
          end
        end
      end
    end
  end

  def invalid_indicators
    Dir.glob("#{ROOT_DIR}/parsed/*.mrc.parsed") do |file|
      File.open("#{file}", 'r') do |input|
        puts "Processing #{file}..."
        File.open("#{ROOT_DIR}/marctofix/invalid_indicators.mrc", 'a') do |output|
          while line = input.gets
            if line.match(/\x1e(?![0-9 ]{2})\x1f/)
              output.write(line.chomp)
            end
          end
        end
      end
    end
  end

  def combining_chars
    Dir.glob("#{ROOT_DIR}/parsed/*.mrc.parsed") do |file|
      File.open("#{file}", 'r') do |input|
        puts "Processing #{file}..."
        File.open("#{ROOT_DIR}/marctofix/combining_chars.mrc", 'a') do |output|
          while line = input.gets
            if line.match(/[^\p{L}\p{M}]\p{M}+/)
              output.write(line.gsub(/([^\p{L}\p{M}]\p{M}+)/, '░\1░').chomp)
            end
          end
        end
      end
    end
  end

  def invalid_chars
    good_chars = Marc_Cleanup::CHARSET.keys
    Dir.glob("#{ROOT_DIR}/parsed/*.mrc.parsed") do |file|
      File.open("#{file}", 'r') do |input|
        puts "Processing #{file}..."
        File.open("#{ROOT_DIR}/marctofix/invalid_chars.mrc", 'a') do |output|
          while line = input.gets
            add_to_file = false
            bad_record = ""
            line.chomp!
            line.each_char do |c|
              if good_chars.include?(c.ord)
                bad_record << c
              else
                bad_record << "░#{c}░"
                add_to_file = true         
              end
            end
            if add_to_file
              output.write(bad_record)
            end
          end 
        end
      end
    end
  end

  def invalid_chars_separate_files
    good_chars = Marc_Cleanup::CHARSET.keys
    puts "What file would you like to process?"
    file = gets.chomp
    File.open("#{file}", 'r') do |input|
      puts "Processing #{file}..."
      File.open("#{ROOT_DIR}/marctofix/invalid_chars.mrc", 'a') do |output|
        while line = input.gets
          add_to_file = false
          bad_record = ""
          line.chomp!
          line.each_char do |c|
            if good_chars.include?(c.ord)
              bad_record << c
            else
              bad_record << "░#{c}░"
              add_to_file = true         
            end
          end
          if add_to_file
            output.write(bad_record)
          end
        end 
      end
    end
  end

  def invalid_xml_chars
    Dir.glob("#{ROOT_DIR}/parsed/*.mrc.parsed") do |file|
      File.open("#{file}", 'r') do |input|
        puts "Processing #{file}..."
        File.open("#{ROOT_DIR}/marctofix/invalid_xml_chars_marked.mrc", 'a') do |output|
          while line = input.gets
            if line.match(/[\u0000-\u0008\u000B\u000C\u000E-\u001C\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF]/)
              line.chomp!
              output.write(line.gsub(/([\u0000-\u0008\u000B\u000C\u000E-\u001C\u007F-\u0084\u0086-\u009F\uFDD0-\uFDEF\uFFFE\uFFFF])/, '░\1░'))
            end
          end
        end
      end
    end
  end

  def invalid_subfield_code
    Dir.glob("#{ROOT_DIR}/parsed/*.mrc.parsed") do |file|
      File.open("#{file}", 'r') do |input|
        puts "Processing #{file}..."
        File.open("#{ROOT_DIR}/marctofix/invalid_subfield_code.mrc", 'a') do |output|
          while line = input.gets
            if line.match(/\x1f[^0-9a-z]/)
              output.write(line.chomp)
            end
          end
        end
      end
    end
  end

  def tab_char
    Dir.glob("#{ROOT_DIR}/parsed/*.mrc.parsed") do |file|
      File.open("#{file}", 'r') do |input|
        puts "Processing #{file}..."
	  File.open("#{ROOT_DIR}/marctofix/tab_char.mrc", 'a') do |output|
          while line = input.gets
            if line.match(/\x09/)
              output.write(line.chomp)
            end
          end
        end
      end
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
