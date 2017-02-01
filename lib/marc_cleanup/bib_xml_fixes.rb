require_relative './../lib/marc_cleanup'
include Marc_Cleanup

def xml_space_fix(record)
  fixed_record = ''
  record_leader = record.match(/<leader>[^<]+<\/leader>/)[0]
  record_fields = record.scan(/(<datafield[^>]*>(?:<subfield code='.'>[^<]*<\/subfield>)*<\/datafield>)|(<controlfield[^>]*>[^<]*<\/controlfield>)/).flatten.delete_if {|value| value == nil}
  record_fields.each do |field|
  if field.match(/^<controlfield/)
    fixed_record << field
  else
    field_tag = field.match(/(?:<datafield.*tag=\')([^']{3})(?:.*)/)[1]
    if field_tag =~ /[1-469]..|0[2-9].|01[1-9]|7[0-5].|5[0-24-9].|53[0-24-9]/
      field.gsub!(/([[:blank:]]){2,}/, '\1')
      fixed_record << field
    elsif field_tag == '533'
      fixed_field = ''
      fixed_field << field.gsub(/^(<datafield[^>]*>).*$/, '\1')
      subfields = field.scan(/<subfield code='.'>[^<]*<\/subfield>/)
      subfields.each do |subfield|
        if subfield.match(/<subfield code=\'[^7]\'/)
          fixed_field << subfield.gsub!(/([[:blank:]]){2,}, '\1')
        else
          fixed_field << subfield
      end
      fixed_record << fixed_field
    elsif field_tag =~ /7[6-8]./
      fixed_field = ''
      fixed_field << field.gsub(/^(<datafield[^>]*>).*$/, '\1')
      subfields = field.scan(/<subfield code='.'>[^<]*<\/subfield>/)
      subfields.each do |subfield|
        if subfield.match(/<subfield code=\'[a-v3-8]\'/)
          fixed_field << subfield.gsub!(/([[:blank:]]){2,}, '\1')
        else
          fixed_field << subfield
        end
      end
      fixed_record << fixed_field
    elsif field_tag =~ /8../
      fixed_field = ''
      fixed_field << field.gsub(/^(<datafield[^>]*>).*$/, '\1')
      subfields = field.scan(/<subfield code='.'>[^<]*<\/subfield>/)
      subfields.each do |subfield|
        if subfield.match(/<subfield code=\'[^w7]\'/)
          fixed_field << subfield.gsub!(/([[:blank:]]){2,}, '\1')
        else
          fixed_field << subfield
      end
      fixed_record << fixed_field
    else
      fixed_record << field
    end
    fixed_
  end
end
