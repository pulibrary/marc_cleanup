require_relative './../lib/marc_cleanup'
include Marc_Cleanup

Dir.glob("#{ROOT_DIR}/marc/*.mrc") do |file|
  filename = File.basename(file)
  File.open("#{file}", 'r') do |input|
    puts "Processing #{filename}..."
    while record = input.gets(sep=END_OF_RECORD)
      corrected = false
      fixed = record
      fixed.scrub!{|bytes| '░'+bytes.unpack('H*')[0]+'░' }.force_encoding("UTF-8")
      if fixed.match(/░/)
        File.open("#{ROOT_DIR}/fixed_marc/byte_sequence.mrc", 'a') do |output|
          output.write(fixed)
        end
      else
        if tab_char(fixed)
         fixed = tab_fix(fixed)
         corrected = true
        end
        if leader_errors(fixed)
          fixed = leaderfix(fixed)
          corrected = true
        end
        if composed_chars(fixed)
          fixed = composed_chars_fix(fixed)
          corrected = true
        end
        if invalid_chars(fixed)
         corrected = true
        end
        if controlchar(fixed)
          fixed = controlcharfix(fixed)
          corrected = true
        end
        if extra_spaces(fixed)
          fixed = extra_space_fix(fixed)
          corrected = true
        end
        if empty_subfield(fixed)
          corrected = true
        end
        if invalid_indicators(fixed)
          corrected = true
        end
        if invalid_subfield_code(fixed)
          corrected = true
        end
        if directory_errors(fixed)
          corrected = true
        end
        if corrected
          File.open("#{ROOT_DIR}/fixed_marc/fixed.mrc", 'a') do |output|
            output.write(fixed)
          end
        end
      end
    end
  end
end
