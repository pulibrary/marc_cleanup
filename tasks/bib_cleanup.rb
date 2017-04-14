require_relative './../lib/marc_cleanup'
include Marc_Cleanup

Dir.glob("#{ROOT_DIR}/marc/*.mrc") do |file|
  File.open("#{file}", 'r') do |input|
    puts "Processing #{file}..."
    while record = input.gets(sep=END_OF_RECORD)
      record.scrub!{|bytes| '░'+bytes.unpack('H*')[0]+'░' }
      record.force_encoding("UTF-8")
      unless record.match(/░/)
        if extra_spaces(record)
          File.open("#{ROOT_DIR}/marctofix/extra_spaces.mrc", 'a') do |output|
            output.write(record.chomp)
          end
        end
        if combining_chars(record.force_encoding("UTF-8"))
          File.open("#{ROOT_DIR}/marctofix/combining_chars.mrc", 'a') do |output|
            output.write(combining_chars(record).chomp)
          end
        end
        if tab_char(record)
          File.open("#{ROOT_DIR}/marctofix/tab_char.mrc", 'a') do |output|
            output.write(record.chomp)
          end
        end
      end
    end
  end
end
