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
            if line.match(/\x1e[0-9 ][^0-9 ]{1}\x1f/) || line.match(/\x1e[^0-9 ][0-9 ]\x1f/)
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

end
