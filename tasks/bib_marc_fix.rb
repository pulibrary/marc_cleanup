require_relative './../lib/marc_cleanup'
include Marc_Cleanup

Dir.glob("#{ROOT_DIR}/marc/*.mrc") do |file|
  filename = File.basename(file)
  File.open("#{file}", 'r') do |input|
    puts "Processing #{filename}..."
    while record = input.gets(sep=END_OF_RECORD)
      corrected = false
      fixed = record
      if extra_spaces(fixed)
        fixed = extra_space_fix(fixed)
        corrected = true
      end
      if tab_char(fixed)
        fixed = tab_fix(fixed)
        corrected = true
      end
      if leader_errors(fixed)
        fixed = leaderfix(fixed)
        corrected = true
      end
      if invalid_chars(fixed)
        fixed = composed_chars(fixed)
        corrected = true
      end
      if invalid_chars(fixed)
        fixed = invalid_chars(fixed)
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
