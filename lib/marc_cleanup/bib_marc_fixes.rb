module Marc_Cleanup

  def leaderfix
    Dir.glob("#{ROOT_DIR}/parsed/*.mrc.parsed") do |file|
      File.open("#{file}", 'r') do |input|
        puts "Processing #{file}..."
        File.open("#{ROOT_DIR}/marctofix/bib_fixed_leader.mrc", 'a') do |output|
          while line = input.gets
            leader = line[0..23].scrub
            to_end = line[24..-1].scrub
            if leader.match(/[0-9]{5}[acdnp][acdefgijkmoprt][abcdims][\sa][\sa]22[0-9]{5}[12345678uzIJKLM\s][aciu\s][abcr\s]4500/) == nil
              length = leader[0, 5]
              if leader.match(/(^.{5})([acdnp])/) == nil
                status = 'n'
              else
                status = leader[5]
              end
              record_type = leader[6]
              bib_level = leader[7]
              if leader.match(/(^.{8})([a ])/) == nil
                control = ' '
              else
                control = leader[8]
              end
              character_scheme = leader[9]
              indsub = '22'
              base_addr = leader[12, 5]
              if leader.match(/(^.{17})([1-8uzIJKLM ])/) == nil
                enc_level = 'u'
              else
                enc_level = leader[17]
              end
              if leader.match(/(^.{18})([aciu ])/) == nil
                cat_form = 'u'
              else
                cat_form = leader[18]
              end
              if leader.match(/(^.{19})([abcr ])/) == nil
                multipart = ' '
              else
                multipart = leader[19]
              end
              final4 = '4500'
              fixed_leader = [length, status, record_type, bib_level, control, character_scheme, indsub, base_addr, enc_level, cat_form, multipart, final4].join
              fixed_record = [fixed_leader, to_end].join
              output.write(fixed_record.chomp)
            end
          end
        end
      end
    end
  end

  def tab_fix
    Dir.glob("#{ROOT_DIR}/parsed/*.mrc.parsed") do |file|
      File.open("#{file}", 'r') do |input|
        puts "Processing #{file}..."
	File.open("#{ROOT_DIR}/marctofix/tab_char.mrc", 'a') do |output|
          while line = input.gets
            if line.match(/\x09/)
              output.write(line.gsub(/\x09/, ' ').chomp)
            end
          end
        end
      end
    end
  end

end
