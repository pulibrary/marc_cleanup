require_relative './../lib/marc_cleanup'
include Marc_Cleanup

Dir.glob("#{ROOT_DIR}/marc/*.*") do |file|
  filename = File.basename(file)
  File.open("#{file}", 'r') do |input|
    puts "Processing #{filename}..."
    while record = input.gets(sep=END_OF_RECORD)
      if heading_end_punct(record)
        File.open("#{ROOT_DIR}/marctofix/heading_end_punct.mrc", 'a') do |output|
          output.write(record.chomp)
        end
      end
      if no_comma_x00(record)
        File.open("#{ROOT_DIR}/marctofix/no_comma_x00.mrc", 'a') do |output|
          output.write(record.chomp)
        end
      end
      if relator_chars(record)
        File.open("#{ROOT_DIR}/marctofix/relator_chars.mrc", 'a') do |output|
          output.write(record.chomp)
        end
      end
      if relator_comma(record)
        File.open("#{ROOT_DIR}/marctofix/relator_comma.mrc", 'a') do |output|
          output.write(record.chomp)
        end
      end
      if x00_subfq(record)
        File.open("#{ROOT_DIR}/marctofix/x00_subfq.mrc", 'a') do |output|
          output.write(record.chomp)
        end
      end
    end
  end
end

