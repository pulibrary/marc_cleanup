require_relative './../lib/marc_cleanup'
include Marc_Cleanup

Dir.glob("#{ROOT_DIR}/marc/*.*") do |file|
  File.open("#{file}", 'r') do |input|
    puts "Processing #{file}..."
    while record = input.gets(sep="\x1d")
      if leader_errors(record)
        File.open("#{ROOT_DIR}/marctofix/leader_errors.mrc", 'a') do |output|
          output.write(record.chomp)
        end
      end
      if directory_errors(record)
        File.open("#{ROOT_DIR}/marctofix/directory_errors.mrc", 'a') do |output|
          output.write(record.chomp)
        end
      end
      if invalid_indicators(record)
        File.open("#{ROOT_DIR}/marctofix/invalid_indicators.mrc", 'a') do |output|
          output.write(record.chomp)
        end
      end
      if invalid_subfield_code(record)
        File.open("#{ROOT_DIR}/marctofix/invalid_subfield_code.mrc", 'a') do |output|
          output.write(record.chomp)
        end
      end
      if invalid_xml_chars(record)
        File.open("#{ROOT_DIR}/marctofix/invalid_xml_chars.mrc", 'a') do |output|
          output.write(record.chomp)
        end
      end
      if empty_subfield(record)
        File.open("#{ROOT_DIR}/marctofix/empty_subfield.mrc", 'a') do |output|
          output.write(record.chomp)
        end
      end
      if no_245(record)
        File.open("#{ROOT_DIR}/marctofix/no_245.mrc", 'a') do |output|
          output.write(record.chomp)
        end
      end
    end
  end
end
