### Derived from
###   https://github.com/reeset/marcrulesfiles/blob/master/marcrules.txt;
### 1xx and required 245 rules (global rules) were removed from the file and
###   added to the validate_marc method;
### stub fields from holdings that are valid in bib records were expanded upon:
###     841, 842, 843, 844, 845, 853-855, 863-868, 876-878;
### fixed fields (001 through 009) were removed;
### after this method was run and the YAML file was generated,
###   the fixed fields were added in by hand;
### Use this method as a starting point to derive a new YAML file
### :source is an object that can be used like a file (File or StringIO)
### :output is an object that can be used like a file (File or StringIO)
### The objects must be opened and closed outside of the method
module MarcCleanup
  def generate_field_yaml(source:, output:)
    hash = {}
    while line = source.gets
      line.chomp!
      if line == ''
        output.puts("'#{hash[:tag]}':")
        output.puts("  repeat: #{hash[:field_repeat]}")
        output.puts("  description: #{hash[:field_description]}")
        output.puts("  ind1: #{hash[:ind1].to_s}")
        output.puts("  ind2: #{hash[:ind2].to_s}")
        output.puts("  subfields:")
        hash[:subfields].each do |subfield|
          output.puts("    '#{subfield[:code]}':")
          output.puts("      repeat: #{subfield[:subf_repeat]}")
          output.puts("      description: #{subfield[:subf_description]}")
        end
        output.puts('')
        hash = {}
      elsif line =~ /^[0-9]{3}/
        parts = line.split("\t")
        hash[:tag] = parts[0]
        repeat = parts[1]
        hash[:field_repeat] = repeat == 'R' ? true : false
        hash[:field_description] = parts[2]
      elsif line =~ /^ind1/
        parts = line.split("\t")
        values = parts[1]
        if values == 'blank'
          hash[:ind1] = [' ']
        else
          values.gsub!(/b/, ' ')
          hash[:ind1] = values.chars
        end
      elsif line =~ /^ind2/
        parts = line.split("\t")
        values = parts[1]
        if values == 'blank'
          hash[:ind2] = [' ']
        else
          values.gsub!(/b/, ' ')
          hash[:ind2] = values.chars
        end
      elsif line =~ /^[0-9a-z]\t/
        hash[:subfields] ||= []
        parts = line.split("\t")
        s_hash = {}
        s_hash[:code] = parts[0]
        subf_repeat = parts[1]
        s_hash[:subf_repeat] = subf_repeat == 'R' ? true : false
        s_hash[:subf_description] = parts[2]
        hash[:subfields] << s_hash
      end
    end
  end
end
