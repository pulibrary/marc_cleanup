require_relative './../lib/marc_cleanup'
include Marc_Cleanup

Dir.glob("#{ROOT_DIR}/marc/*.mrc") do |file|
  filename = File.basename(file)
  File.open("#{file}", 'r') do |input|
    puts "Processing #{filename}..."
    while record = input.gets(sep=END_OF_RECORD)
      record.scrub!{|bytes| '░'+bytes.unpack('H*')[0]+'░' } if record
      if invalid_chars(record)
        File.open("#{ROOT_DIR}/marctofix/invalid_chars.mrc", 'a') do |output|
          output.write(invalid_chars(record).chomp)
        end
      end
    end
  end
end
