module Marc_Cleanup

  def no_245
    Dir.glob("#{ROOT_DIR}/xml/*.xml") do |file|
      File.open("#{file}", 'r') do |input|
        File.open("#{ROOT_DIR}/logs/no_245.log", 'a') do |output|
          while line = input.gets
            if line.match(/^<record>/)
              bib_id = line.gsub(/(^<record><leader>[^<]*<\/leader>)(<controlfield tag='001'>)([0-9]*)(<.+$)/, '\3')
              matchdata = line.scan(/(<datafield ind1='.' ind2='.' tag='245'>)/)
              if matchdata.to_s == "[]"
                output.puts(bib_id)
              end
            end
          end
        end
      end
    end
  end

  def empty_field
    Dir.glob("#{ROOT_DIR}/xml/*.xml") do |file|
      File.open("#{file}", 'r') do |input|
        File.open("#{ROOT_DIR}/logs/empty_field.log", 'a') do |output|
          while line = input.gets
            bib_id = line.gsub(/(^<record><leader>[^<]*<\/leader>)(<controlfield tag='001'>)([0-9]*)(<.+$)/, '\3')
            matchdata = line.scan(/(<datafield ind1='.' ind2='.' tag='...'>)(<\/datafield>)/)
            unless matchdata.to_s == "[]"
              bibmatch = matchdata.map{|item| bib_id.chomp + "░" + item.to_s }
              output.puts(bibmatch.to_s.gsub(/\\\"/,"").gsub(/(\"\,) /,"\"\,\n").gsub(/\"\,/, "").gsub(/\"\]/, "").gsub(/\[\"/, "").gsub(/\]/, "").gsub(/^\"/, ""))
            end
          end
        end
      end
    end
  end

  def empty_subfield
    Dir.glob("#{ROOT_DIR}/xml/*.xml") do |file|
      File.open("#{file}", 'r') do |input|
        File.open("#{ROOT_DIR}/logs/empty_subfield.log", 'a') do |output|
          while line = input.gets
            bib_id = line.gsub(/(^<record><leader>[^<]*<\/leader>)(<controlfield tag='001'>)([0-9]*)(<.+$)/, '\3')
            matchdata = line.scan(/(<datafield ind1='.' ind2='.' tag='...'>)((?:<subfield code='.'><\/subfield>)+)(?:(?:<subfield code='.'>[^<]*<\/subfield>)*)(<\/datafield>)/)
            unless matchdata.to_s == "[]"
              bibmatch = matchdata.map{|item| bib_id.chomp + "░" + item.to_s }
              output.puts(bibmatch.to_s.gsub(/\\\"/,"").gsub(/(\"\,) /,"\"\,\n").gsub(/\"\,/, "").gsub(/\"\]/, "").gsub(/\[\"/, "").gsub(/\]/, "").gsub(/^\"/, ""))
            end
          end
        end
      end
    end
  end

  def invalid_subfield_code_xml
    Dir.glob("#{ROOT_DIR}/xml/*.xml") do |file|
      File.open("#{file}", 'r') do |input|
        File.open("#{ROOT_DIR}/logs/invalid_subfield_code.log", 'a') do |output|
          while line = input.gets
            bib_id = line.gsub(/(^<record><leader>[^<]*<\/leader>)(<controlfield tag='001'>)([0-9]*)(<.+$)/, '\3')
            matchdata = line.scan(/(<datafield ind1='.' ind2='.' tag='...'>)(?:(?:<subfield code='.'>[^<]*<\/subfield>)*)((?:<subfield code='[^a-z0-9]'>[^<]*<\/subfield>)+)(?:(?:<subfield code='.'>[^<]*<\/subfield>)*)(<\/datafield>)/)
            unless matchdata.to_s == "[]"
              bibmatch = matchdata.map{|item| bib_id.chomp + "░" + item.to_s }
              output.puts(bibmatch.to_s.gsub(/\\\"/,"").gsub(/(\"\,) /,"\"\,\n").gsub(/\"\,/, "").gsub(/\"\]/, "").gsub(/\[\"/, "").gsub(/\]/, "").gsub(/^\"/, ""))
            end
          end
        end
      end
    end
  end

  def no_comma_x00
    Dir.glob("#{ROOT_DIR}/xml/*.xml") do |file|
      File.open("#{file}", 'r') do |input|
        File.open("#{ROOT_DIR}/logs/no_comma_x00.log", 'a') do |output|
          while line = input.gets
            bib_id = line.gsub(/(^<record><leader>[^<]*<\/leader>)(<controlfield tag='001'>)([0-9]*)(<.+$)/, '\3')
            matchdata = line.scan(/(<datafield ind1='.' ind2='.' tag='[167]00'>)(?:(?:<subfield code='[^a]'>[^<]*<\/subfield>)*)(<subfield code='a'>[^<]*[^,]<\/subfield><subfield code='d'>[^<]*<\/subfield>)(?:(?:<subfield code='.'>[^<]*<\/subfield>)*)(<\/datafield>)/)
            unless matchdata.to_s == "[]"
              bibmatch = matchdata.map{|item| bib_id.chomp + "░" + item.to_s }
              output.puts(bibmatch.to_s.gsub(/\\\"/,"").gsub(/(\"\,) /,"\"\,\n").gsub(/\"\,/, "").gsub(/\"\]/, "").gsub(/\[\"/, "").gsub(/\]/, "").gsub(/^\"/, ""))
            end
          end
        end
      end
    end
  end

  def lowercase_headings
    Dir.glob("#{ROOT_DIR}/xml/*.xml") do |file|
      File.open("#{file}", 'r') do |input|
        File.open("#{ROOT_DIR}/logs/lowercase_headings.log", 'a') do |output|
          while line = input.gets
            bib_id = line.gsub(/(^<record><leader>[^<]*<\/leader>)(<controlfield tag='001'>)([0-9]*)(<.+$)/, '\3')
            matchdata = line.scan(/(<datafield ind1='.' ind2='.' tag='[167]..'>)(?:(?:<subfield code='[^a]'>[^<]*<\/subfield>)*)(<subfield code='a'>[a-z]{3,}[^<]*<\/subfield>)((?:<subfield code='.'>[^<]*<\/subfield>)*)(<\/datafield>)/)
            unless matchdata.to_s == "[]"
              bibmatch = matchdata.map{|item| bib_id.chomp + "░" + item.to_s }
              if bibmatch.to_s.match("<subfield code='a'>ebrary, Inc.</subfield>") == nil
                output.puts(bibmatch.to_s.gsub(/\\\"/,"").gsub(/(\"\,) /,"\"\,\n").gsub(/\"\,/, "").gsub(/\"\]/, "").gsub(/\[\"/, "").gsub(/\]/, "").gsub(/^\"/, ""))
              end
            end
          end
        end
      end
    end
  end

  def x00_subfq
    Dir.glob("#{ROOT_DIR}/xml/*.xml") do |file|
      File.open("#{file}", 'r') do |input|
        File.open("#{ROOT_DIR}/logs/x00_subfq.log", 'a') do |output|
          while line = input.gets
            bib_id = line.gsub(/(^<record><leader>[^<]*<\/leader>)(<controlfield tag='001'>)([0-9]*)(<.+$)/, '\3')
            matchdata = line.scan(/((?:<datafield ind1='.' ind2='.' tag='[167]00'>)(?:<subfield code='[^q]'>[^<]*<\/subfield>)*(?:<subfield code='q'>[^\(][^\)<]*<\/subfield>)(?:<subfield code='.'>[^<]*<\/subfield>)*(?:<\/datafield>))/)
            unless matchdata.to_s == "[]"
              bibmatch = matchdata.map{|item| bib_id.chomp + "░" + item.to_s }
              output.puts(bibmatch.to_s.gsub(/\\\"/,"").gsub(/(\"\,) /,"\"\,\n").gsub(/\"\,/, "").gsub(/\"\]/, "").gsub(/\[\"/, "").gsub(/\]/, "").gsub(/^\"/, "").gsub(/░\[/, "░"))
            end
          end
        end
      end
    end
  end

  def heading_end_punct
    Dir.glob("#{ROOT_DIR}/xml/*.xml") do |file|
      File.open("#{file}", 'r') do |input|
        File.open("#{ROOT_DIR}/logs/heading_end_punct.log", 'a') do |output|
          while line = input.gets
            bib_id = line.gsub(/(^<record><leader>[^<]*<\/leader>)(<controlfield tag='001'>)([0-9]*)(<.+$)/, '\3')
            matchdata = line.scan(/((?:<datafield ind1='.' ind2='.' tag='[1678][013][01]'>)(?:<subfield code='[a-z8]'>[^<]*<\/subfield>)*(?:<subfield code='[a-z8]'>[^<]*[^\).\?\-]<\/subfield>)(?:<subfield code='[^a-z8]'>[^<]<\/subfield>)*(?:<\/datafield>))/)
            unless matchdata.to_s == "[]"
              bibmatch = matchdata.map{|item| bib_id.chomp + "░" + item.to_s }
              output.puts(bibmatch.to_s.gsub(/\\\"/,"").gsub(/(\"\,) /,"\"\,\n").gsub(/\"\,/, "").gsub(/\"\]/, "").gsub(/\[\"/, "").gsub(/\]/, "").gsub(/^\"/, "").gsub(/░\[/, "░"))
            end
          end
        end
      end
    end
  end

  def relator_comma
    Dir.glob("#{ROOT_DIR}/xml/*.xml") do |file|
      File.open("#{file}", 'r') do |input|
        File.open("#{ROOT_DIR}/logs/relator_comma.log", 'a') do |output|
          while line = input.gets
            bib_id = line.gsub(/(^<record><leader>[^<]*<\/leader>)(<controlfield tag='001'>)([0-9]*)(<.+$)/, '\3')
            matchdata = line.scan(/((?:<datafield ind1='.' ind2='.' tag='[17][01]0'>)(?:<subfield code='[^e]'>[^<]*<\/subfield>)*(?:<subfield code='[^e]'>[^<]*[^\-,]<\/subfield>)(?:<subfield code='e'>[^<]*<\/subfield>)(?:<subfield code='.'>[^<]*<\/subfield>)*(?:<\/datafield>))|((?:<datafield ind1='.' ind2='.' tag='[17]11'>)(?:<subfield code='[^j]'>[^<]*<\/subfield>)*(?:<subfield code='[^j]'>[^<]*[^\-,]<\/subfield>)(?:<subfield code='j'>[^<]*<\/subfield>)(?:<subfield code='.'>[^<]*<\/subfield>)*(?:<\/datafield>))/)
            unless matchdata.to_s == "[]"
              bibmatch = matchdata.map{|item| bib_id.chomp + "░" + item.to_s }
              output.puts(bibmatch.to_s.gsub(/\\\"/,"").gsub(/(\"\,) /,"\"\,\n").gsub(/\"\,/, "").gsub(/\"\]/, "").gsub(/\[\"/, "").gsub(/\]/, "").gsub(/^\"/, "").gsub(/░\[/, "░").gsub(/>, nil$/, ">").gsub(/░nil, /, "░"))
            end
          end
        end
      end
    end
  end

  def relator_case
    Dir.glob("#{ROOT_DIR}/xml/*.xml") do |file|
      File.open("#{file}", 'r') do |input|
        File.open("#{ROOT_DIR}/logs/relator_case.log", 'a') do |output|
          while line = input.gets
            bib_id = line.gsub(/(^<record><leader>[^<]*<\/leader>)(<controlfield tag='001'>)([0-9]*)(<.+$)/, '\3')
            matchdata = line.scan(/((?:<datafield ind1='.' ind2='.' tag='[17][01]0'>)(?:<subfield code='[^e]'>[^<]*<\/subfield>)*(?:<subfield code='e'>[^<]*[A-Z0-9]+[^<]*<\/subfield>)(?:<subfield code='.'>[^<]*<\/subfield>)*(?:<\/datafield>))|((?:<datafield ind1='.' ind2='.' tag='[17]11'>)(?:<subfield code='[^j]'>[^<]*<\/subfield>)*(?:<subfield code='j'>[A-Z0-9]+[^<]*<\/subfield>)(?:<subfield code='.'>[^<]*<\/subfield>)*(?:<\/datafield>))/)
            unless matchdata.to_s == "[]"
              bibmatch = matchdata.map{|item| bib_id.chomp + "░" + item.to_s }
              output.puts(bibmatch.to_s.gsub(/\\\"/,"").gsub(/(\"\,) /,"\"\,\n").gsub(/\"\,/, "").gsub(/\"\]/, "").gsub(/\[\"/, "").gsub(/\]/, "").gsub(/^\"/, "").gsub(/░\[/, "░").gsub(/>, nil$/, ">").gsub(/░nil, /, "░"))
            end
          end
        end
      end
    end
  end

  def tab_char_xml
    Dir.glob("#{ROOT_DIR}/xml/*.xml") do |file|
      File.open("#{file}", 'r') do |input|
        File.open("#{ROOT_DIR}/logs/tab_char.log", 'a') do |output|
          while line = input.gets
            bib_id = line.gsub(/(^<record><leader>[^<]*<\/leader>)(<controlfield tag='001'>)([0-9]*)(<.+$)/, '\3')
            matchdata = line.scan(/(<datafield ind1='.' ind2='.' tag='...'>)(?:<subfield code='.'>[^<]*<\/subfield>)*((?:<subfield code='.'>[^<]\x09[^<]*<\/subfield>)+)(?:(?:<subfield code='.'>[^<]*<\/subfield>)*)(<\/datafield>)/)
            unless matchdata.to_s == "[]"
              bibmatch = matchdata.map{|item| bib_id.chomp + "░" + item.to_s }
              output.puts(bibmatch.to_s.gsub(/\\\"/,"").gsub(/(\"\,) /,"\"\,\n").gsub(/\"\,/, "").gsub(/\"\]/, "").gsub(/\[\"/, "").gsub(/\]/, "").gsub(/^\"/, ""))
            end
          end
        end
      end
    end
  end

  def heading_spaces
    Dir.glob("#{ROOT_DIR}/xml/*.xml") do |file|
      File.open("#{file}", 'r') do |input|
        File.open("#{ROOT_DIR}/logs/heading_spaces_bibs.log", 'a') do |output|
          while line = input.gets
            bib_id = line.gsub(/(^<record><leader>[^<]*<\/leader>)(<controlfield tag='001'>)([0-9]*)(<.+$)/, '\3')
            matchdata = line.scan(/(<datafield ind1='.' ind2='.' tag='[167][0-5].'>)(?:<subfield code='.'>[^<]*<\/subfield>)*((?:<subfield code='.'>[^<]*[\s]{2,}[^<]*<\/subfield>)+)((?:<subfield code='.'>[^<]*<\/subfield>)*)(<\/datafield>)|(<datafield ind1='.' ind2='.' tag='[167][0-5].'>)(?:<subfield code='.'>[^<]*<\/subfield>)*((?:<subfield code='.'>[^<]*\s+<\/subfield>)+)((?:<subfield code='.'>[^<]*<\/subfield>)*)(<\/datafield>)|(<datafield ind1='.' ind2='.' tag='240'>)(?:<subfield code='.'>[^<]*<\/subfield>)*((?:<subfield code='.'>[^<]*[\s]{2,}[^<]*<\/subfield>)+)(?:<subfield code='.'>[^<]*<\/subfield>)*(<\/datafield>)/)
            unless matchdata.to_s == "[]"
  	    output.puts(bib_id)
            end
          end
        end
      end
    end
  end

  def extra_spaces
    Dir.glob("#{ROOT_DIR}/xml/*.xml") do |file|
      File.open("#{file}", 'r') do |input|
        File.open("#{ROOT_DIR}/logs/extra_spaces_bibs.log", 'a') do |output|
          while line = input.gets
            bib_id = line.gsub(/(^<record><leader>[^<]*<\/leader>)(<controlfield tag='001'>)([0-9]*)(<.+$)/, '\3')
            matchdata = line.scan(/(<datafield ind1='.' ind2='.' tag='[1-469]..'>)(?:<subfield code='.'>[^<]*<\/subfield>)*((?:<subfield code='.'>[^<]*[\s]{2,}[^<]*<\/subfield>)+)((?:<subfield code='.'>[^<]*<\/subfield>)*)(<\/datafield>)|(<datafield ind1='.' ind2='.' tag='0[2-9].'>)(?:<subfield code='.'>[^<]*<\/subfield>)*((?:<subfield code='.'>[^<]*[\s]{2,}[^<]*<\/subfield>)+)(?:<subfield code='.'>[^<]*<\/subfield>)*(<\/datafield>)|(<datafield ind1='.' ind2='.' tag='7[0-5].'>)(?:<subfield code='.'>[^<]*<\/subfield>)*((?:<subfield code='.'>[^<]*[\s]{2,}[^<]*<\/subfield>)+)(?:<subfield code='.'>[^<]*<\/subfield>)*(<\/datafield>)|(<datafield ind1='.' ind2='.' tag='7[6-8].'>)(?:<subfield code='.'>[^<]*<\/subfield>)*((?:<subfield code='[a-v3-8]'>[^<]*[\s]{2,}[^<]*<\/subfield>)+)(?:<subfield code='.'>[^<]*<\/subfield>)*(<\/datafield>)|(<datafield ind1='.' ind2='.' tag='8..'>)(?:<subfield code='.'>[^<]*<\/subfield>)*((?:<subfield code='[^w7]'>[^<]*[\s]{2,}[^<]*<\/subfield>)+)(?:<subfield code='.'>[^<]*<\/subfield>)*(<\/datafield>)|(<datafield ind1='.' ind2='.' tag='[5]..'>)(?:<subfield code='.'>[^<]*<\/subfield>)*((?:<subfield code='[^7]'>[^<]*[\s]{2,}[^<]*<\/subfield>)+)((?:<subfield code='.'>[^<]*<\/subfield>)*)(<\/datafield>)/)
            unless matchdata.to_s == "[]"
              output.puts(bib_id)
            end
          end
        end
      end
    end
  end

  def error_match_user_input
    puts "What pattern would you like to search for in the MARCXML records?"
    search_string = gets.chomp
    search_regex = Regexp.new(search_string)
    Dir.glob("#{ROOT_DIR}/xml/*.xml") do |file|
      File.open("#{file}", 'r') do |input|
        File.open("#{ROOT_DIR}/logs/custom_search.log", 'a') do |output|
          while line = input.gets
          bib_id = line.gsub(/(^<record><leader>[^<]*<\/leader>)(<controlfield tag='001'>)([0-9]*)(<.+$)/, '\3')
          matchdata = line.scan(search_regex)
            unless matchdata.to_s == "[]"
              bibmatch = matchdata.map{|item| bib_id.chomp + "░" + item.to_s.gsub(/([^<]*)(<.*)/, '\2') }
              output.puts(bibmatch.to_s.gsub(/\\\"/,"").gsub(/(\"\,) /,"\"\,\n").gsub(/\"\,/, "").gsub(/\"\]/, "").gsub(/\[\"/, "").gsub(/\]/, "").gsub(/^\"/, ""))
            end
          end
        end
      end
    end
  end

  def error_match_user_input_with_holdings
    puts "What pattern would you like to search for in the MARCXML records?"
    search_string = gets.chomp
    search_regex = Regexp.new(search_string)
    Dir.glob("#{ROOT_DIR}/xml/*.xml") do |file|
      File.open("#{file}", 'r') do |input|
        File.open("#{ROOT_DIR}/logs/custom_search.log", 'a') do |output|
          while line = input.gets
          bib_id = line.gsub(/(^<record><leader>[^<]*<\/leader>)(<controlfield tag='001'>)([0-9]*)(<.+$)/, '\3')
          holdings_info = line.scan(/(<datafield ind1='.' ind2='.' tag='852'>)(?:<subfield code='[^b]'>[^<]*<\/subfield>)*(<subfield code='b'>[^<]*<\/subfield>)(?:<subfield code='[^b]'>[^<]*<\/subfield>)*(<\/datafield>)/)
          matchdata = line.scan(search_regex)
            unless matchdata.to_s == "[]"
              bibmatch = matchdata.map{|item| bib_id.chomp + "░" + item.to_s.gsub(/([^<]*)(<.*)/, '\2') + "░" + holdings_info.to_s.gsub(/([^<]*)(<.*)/, '\2').gsub(/, /, "") }
              output.puts(bibmatch.to_s.gsub(/\\\"/,"").gsub(/(\"\,) /,"\"\,\n").gsub(/\"\,/, "").gsub(/\"\]/, "").gsub(/\[\"/, "").gsub(/\]/, "").gsub(/^\"/, ""))
            end
          end
        end
      end
    end
  end
end
