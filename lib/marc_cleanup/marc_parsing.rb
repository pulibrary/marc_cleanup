module Marc_Cleanup

  def separate_lines
    marc_dir = "#{ROOT_DIR}/marc"
    last_file = Dir[File.join(marc_dir, '*')].count { |file| File.file?(file) }
    file_num = 0
    loop do
      file_num += 1
      break if file_num > last_file
      File.open("#{ROOT_DIR}/marc/#{file_num}.mrc", 'r') do |input|
        File.open("#{ROOT_DIR}/parsed/#{file_num}.mrc.parsed", 'a') do |output|
          while line = input.gets
            output.puts(line.scrub{|bytes| '░'+bytes.unpack('H*')[0]+'░' }.gsub(/\x1d/, "\x1d\n"))
          end
        end
      end
    end
  end

 def to_xml
    marc_dir = "#{ROOT_DIR}/marc"
    last_file = Dir[File.join(marc_dir, '*')].count { |file| File.file?(file) }
    file_num = 0
    loop do
      file_num += 1
      break if file_num > last_file
      reader = MARC::Reader.new("#{ROOT_DIR}/marc/#{file_num}.mrc", :external_encoding => "UTF-8")
      writer = MARC::XMLWriter.new("#{ROOT_DIR}/xml/#{file_num}.xml")
      for record in reader
        writer.write(record)
      end
    writer.close()
    end
  end
end
