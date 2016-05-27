require 'oci8'

module Marc_Cleanup

  def auth_dump
    conn = OCI8.new(USER, PASS, NAME)
    cursor = conn.exec('SELECT TO_CHAR(MAX(AUTH_ID)) AS MAX FROM AUTH_DATA')
    row = cursor.fetch_hash
    cursor.close
    last_record = row['MAX'].to_i
    last_file_num = (last_record.to_f/500000).ceil
    file_num = 0

    loop do
      file_num += 1
      break if file_num > last_file_num
      File.open("#{ROOT_DIR}/auth_marc/#{file_num}.mrc", 'a') do |output|
        conn.exec("SELECT RECORD_SEGMENT FROM AUTH_DATA WHERE AUTH_ID >= 1+((#{file_num}-1)*500000) AND AUTH_ID <= 500000+((#{file_num}-1)*500000) ORDER BY AUTH_ID,SEQNUM") do |r|
          output.write(r.join(''))
        end
      end
    end
    conn.logoff
  end

  def auth_separate_lines
    marc_dir = "#{ROOT_DIR}/auth_marc"
    last_file = Dir[File.join(marc_dir, '*')].count { |file| File.file?(file) }
    file_num = 0
    loop do
      file_num += 1
      break if file_num > last_file
      File.open("#{marc_dir}/#{file_num}.mrc", 'r') do |input|
        File.open("#{ROOT_DIR}/auth_parsed/#{file_num}.mrc.parsed", 'a') do |output|
          while line = input.gets
            output.puts(line.scrub{|bytes| '░'+bytes.unpack('H*')[0]+'░' }.gsub(/\x1d/, "\x1d\n"))
          end
        end
      end
    end
  end

 def auth_to_xml
    marc_dir = "#{ROOT_DIR}/../auth_marc"
    last_file = Dir[File.join(marc_dir, '*')].count { |file| File.file?(file) }
    file_num = 0
    loop do
      file_num += 1
      break if file_num > last_file
      reader = MARC::Reader.new("#{marc_dir}/#{file_num}.mrc", :external_encoding => "UTF-8")
      writer = MARC::XMLWriter.new("#{ROOT_DIR}/auth_xml/#{file_num}.xml")
      for record in reader
        writer.write(record)
      end
    writer.close()
    end
  end

  def auth_directory_errors
    Dir.glob("#{ROOT_DIR}/auth_parsed/*.mrc.parsed") do |file|
      File.open("#{file}", 'r') do |input|
        puts "Processing #{file}..."
        File.open("#{ROOT_DIR}/marctofix/auth_directory_errors.mrc", 'a') do |output|
          while line = input.gets
            if line.scrub.match(/^.{24}([0-9]{12})+[\x1e]/) == nil
              output.write(line.chomp)
            end
          end
        end
      end
    end
  end

  def auth_invalid_indicators
    Dir.glob("#{ROOT_DIR}/auth_parsed/*.mrc.parsed") do |file|
      File.open("#{file}", 'r') do |input|
        puts "Processing #{file}..."
        File.open("#{ROOT_DIR}/marctofix/auth_invalid_indicators.mrc", 'a') do |output|
          while line = input.gets
            if line.match(/\x1e[0-9 ][^0-9 ]{1}\x1f/) || line.match(/\x1e[^0-9 ][0-9 ]\x1f/)
              output.write(line.chomp)
            end
          end
        end
      end
    end
  end

  def auth_invalid_subfield_code
    Dir.glob("#{ROOT_DIR}/auth_parsed/*.mrc.parsed") do |file|
      File.open("#{file}", 'r') do |input|
        puts "Processing #{file}..."
        File.open("#{ROOT_DIR}/marctofix/auth_invalid_subfield_code.mrc", 'a') do |output|
          while line = input.gets
            if line.match(/\x1f[^0-9a-z]/)
              output.write(line.chomp)
            end
          end
        end
      end
    end
  end

end
