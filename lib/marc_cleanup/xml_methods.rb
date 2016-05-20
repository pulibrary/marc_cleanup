module Marc_Cleanup

  def no_245
    Dir.glob('./../xml/*.xml') do |file|
      File.open("#{file}", 'r') do |input|
        File.open('./../logs/no_245.log', 'a') do |output|
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
    Dir.glob('./../xml/*.xml') do |file|
      File.open("#{file}", 'r') do |input|
        File.open('./../logs/empty_field.log', 'a') do |output|
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
    Dir.glob('./../xml/*.xml') do |file|
      File.open("#{file}", 'r') do |input|
        File.open('./../logs/empty_subfield.log', 'a') do |output|
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
    Dir.glob('./../xml/*.xml') do |file|
      File.open("#{file}", 'r') do |input|
        File.open('./../logs/invalid_subfield_code.log', 'a') do |output|
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
    Dir.glob('./../xml/*.xml') do |file|
      File.open("#{file}", 'r') do |input|
        File.open('./../logs/no_comma_x00.log', 'a') do |output|
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
    Dir.glob('./../xml/*.xml') do |file|
      File.open("#{file}", 'r') do |input|
        File.open('./../logs/lowercase_headings.log', 'a') do |output|
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

  def tab_char_xml
    Dir.glob('./../xml/*.xml') do |file|
      File.open("#{file}", 'r') do |input|
        File.open('./../logs/tab_char.log', 'a') do |output|
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
    Dir.glob('./../xml/*.xml') do |file|
      File.open("#{file}", 'r') do |input|
        File.open('./../logs/heading_spaces_bibs.log', 'a') do |output|
          while line = input.gets
            bib_id = line.gsub(/(^<record><leader>[^<]*<\/leader>)(<controlfield tag='001'>)([0-9]*)(<.+$)/, '\3')
            matchdata = line.scan(/(<datafield ind1='.' ind2='.' tag='[167][0-5].'>)(?:<subfield code='.'>[^<]*<\/subfield>)*((?:<subfield code='.'>[^<]*[\s]{2,}[^<]*<\/subfield>)+)((?:<subfield code='.'>[^<]*<\/subfield>)*)(<\/datafield>)|(<datafield ind1='.' ind2='.' tag='240'>)(?:<subfield code='.'>[^<]*<\/subfield>)*((?:<subfield code='.'>[^<]*[\s]{2,}[^<]*<\/subfield>)+)(?:<subfield code='.'>[^<]*<\/subfield>)*(<\/datafield>)/)
            unless matchdata.to_s == "[]"
  	    output.puts(bib_id)
            end
          end
        end
      end
    end
  end

  def extra_spaces
    Dir.glob('./../xml/*.xml') do |file|
      File.open("#{file}", 'r') do |input|
        File.open('./../logs/extra_spaces_bibs.log', 'a') do |output|
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
    Dir.glob('./../xml/*.xml') do |file|
      File.open("#{file}", 'r') do |input|
        File.open('./../logs/custom_search.log', 'a') do |output|
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
    Dir.glob('./../xml/*.xml') do |file|
      File.open("#{file}", 'r') do |input|
        File.open('./../logs/custom_search.log', 'a') do |output|
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
