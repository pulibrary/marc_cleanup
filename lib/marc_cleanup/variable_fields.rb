module MarcCleanup
  # http://www.loc.gov/standards/valuelist/marcauthen.html
  def auth_codes_042
    %w[
      anuc
      croatica
      dc
      dhca
      dlr
      gamma
      gils
      gnd1
      gnd2
      gnd3
      gnd4
      gnd5
      gnd6
      gnd7
      gndz
      isds/c
      issnuk
      lacderived
      lc
      lcac
      lccopycat
      lccopycat-nm
      lcd
      lcderive
      lchlas
      lcllh
      lcnccp
      lcnitrate
      lcnuc
      lcode
      msc
      natgaz
      nbr
      nlc
      nlmcopyc
      norbibl
      nsdp
      nst
      ntccf
      nznb
      pcc
      premarc
      reveal
      sanb
      scipio
      toknb
      ukblcatcopy
      ukblderived
      ukblproject
      ukblsr
      ukscp
      xisds/c
      xissnuk
      xlc
      xnlc
      xnsdp
    ]
  end

  def auth_code_error?(record)
    return false unless record['042']
    auth_codes_042.include?(record['042']['a']) ? false : true
  end

  def invalid_indicators?(record)
    record.fields.each do |field|
      next unless field.class == MARC::DataField
      return true unless field.indicator1 =~ /^[0-9 ]$/ && field.indicator2 =~ /^[0-9 ]$/
    end
    false
  end

  def invalid_subfield_code?(record)
    record.fields.each do |field|
      next unless field.class == MARC::DataField
      field.subfields.each do |subfield|
        return true unless subfield.code =~ /^[0-9a-z]$/
      end
    end
    false
  end

  def empty_subfields?(record)
    record.fields.each do |field|
      next unless field.class == MARC::DataField
      field.subfields.each do |subfield|
        return true if subfield.value =~ /^[[:blank:]]*$/
      end
    end
    false
  end

  def extra_spaces?(record)
    blank_regex = /^.*[[:blank:]]{2,}.*$|^.*[[:blank:]]+$|^[[:blank:]]+(.*)$/
    record.fields.each do |field|
      next unless field.class == MARC::DataField && field.tag != '010'
      if field.tag =~ /[1-469]..|0[2-9].|01[1-9]|7[0-5].|5[0-24-9].|53[0-24-9]/
        field.subfields.each do |subfield|
          return true if subfield.value =~ blank_regex
        end
      elsif field.tag == '533'
        field.subfields.each do |subfield|
          next if subfield.code == '7'
          return true if subfield.value =~ blank_regex
        end
      elsif field.tag =~ /7[6-8]./
        field.subfields.each do |subfield|
          next unless subfield.code =~ /[a-v3-8]/
          return true if subfield.value =~ blank_regex
        end
      elsif field.tag =~ /8../
        field.subfields.each do |subfield|
          next unless subfield.code =~ /[^w7]/
          return true if subfield.value =~ blank_regex
        end
      end
    end
    false
  end

  def multiple_no_040?(record)
    f040 = record.fields('040')
    f040.size != 1
  end

  def multiple_no_040b?(record)
    f040 = record.fields('040')
    return true if f040.size != 1
    f040 = f040.first
    b040 = f040.subfields.select { |subfield| subfield.code == 'b' }
    return true if b040.size != 1
    b040 = b040.first.value
    b040.gsub!(/[ ]/, '')
    b040 == ''
  end

  def f046_subfield_errors?(record)
    f046 = record.fields('046')
    return false if f046.empty?
    f046.each do |field|
      subf_codes = field.subfields.map { |subfield| subfield.code }
      return true if field['a'].nil? && (subf_codes & %w[b c d e]).size > 0
    end
    false
  end

  def multiple_no_245?(record)
    record.fields('245').size != 1
  end

  def f245_subfield_errors?(record)
    fields = record.fields('245')
    return true if fields.empty?
    fields.each do |field|
      subfields = field.subfields.map(&:code)
      return true if subfields.count('a') != 1
      return true if subfields.count('b') > 1
      return true if subfields.count('c') > 1
    end
    false
  end

  def missing_040c?(record)
    return true unless record['040'] && record['040']['c']
    false
  end

  def pair_880_errors?(record)
    pair_880s = []
    linked_fields = []
    return false unless record['880']
    record.fields.each do |field|
      return true if field.tag == '880' && field['6'].nil?
      next unless field.tag =~ /^[0-8]..$/ && field.class == MARC::DataField && field['6']
      if field.tag == '880'
        pair_880s << field['6'].gsub(/^([0-9]{3}-[0-9]{2}).*$/, '\1')
      else
        linked_fields << "#{field.tag}-#{field['6'].gsub(/^880-([0-9]{2}).*$/, '\1').chomp}"
      end
    end
    pair_880s.delete_if { |x| x =~ /^.*-00/ }
    return true if pair_880s.uniq != pair_880s || pair_880s.uniq.sort != linked_fields.uniq.sort
    false
  end

  def has_130_240?(record)
    (%w[130 240] - record.tags).empty?
  end

  def multiple_1xx?(record)
    record.fields('100'..'199').size > 1
  end

  def relator_chars?(record)
    record.fields.each do |field|
      if field.tag =~ /[17][01]0/
        field.subfields.each do |subfield|
          next unless subfield.code == 'e' && subfield.value =~ /.*[^a-z, \.].*/
          return true
        end
      elsif field.tag =~ /[17]11/
        field.subfields.each do |subfield|
          next unless subfield.code == 'j' && subfield.value =~ /.*[^a-z, \.].*/
          return true
        end
      end
    end
    false
  end

  def x00_subfq?(record)
    record.fields(%w[100 600 700 800]).each do |field|
      field.subfields.each do |subfield|
        next unless subfield.code == 'q' && subfield.value =~ /^(?!\([^\)]*\))$/
        return true
      end
    end
    false
  end

  def no_comma_x00?(record)
    record.fields(%w[100 600 700 800]).each do |field|
      code_array = ''
      field.subfields.each do |subfield|
        code_array << subfield.code
      end
      subfx_d_index = code_array.index(/.d/)
      return true if subfx_d_index && field.subfields[subfx_d_index].value =~ /^.*[^,]$/
    end
    false
  end

  def relator_comma?(record)
    comma_regex = /^.*[^,]$/
    record.fields.each do |field|
      next unless field.tag =~ /[17][01][01]/
      code_array = ''
      field.subfields.each do |subfield|
        code_array << subfield.code
      end
      if field.tag =~ /[17][01]0/
        subfx_e_index = code_array.index(/.e/)
        return true if subfx_e_index && field.subfields[subfx_e_index].value =~ comma_regex
      elsif field.tag =~ /[17]11/
        subfx_j_index = code_array.index(/.j/)
        return true if subfx_j_index && field.subfields[subfx_j_index].value =~ comma_regex
      end
    end
    false
  end

  def heading_end_punct?(record)
    punct_regex = /.*[^"\).\!\?\-]$/
    record.fields.each do |field|
      next unless field.tag =~ /^[167][0-5].$/ && field.indicator2 =~ /[^47]/
      code_array = ''
      field.subfields.each do |subfield|
        code_array << subfield.code
      end
      last_heading_subfield_index = code_array.index(/[a-vx-z8][^a-vx-z8]*$/)
      return true if last_heading_subfield_index && field.subfields[last_heading_subfield_index].value =~ punct_regex
    end
    false
  end

  def lowercase_headings?(record)
    record.fields.each do |field|
      next unless field.tag =~ /[1678]../
      return true if field['a'] =~ /^[a-z]{3,}/
    end
    false
  end

  def subf_0_uri?(record)
    record.fields.each do |field|
      next unless field.class == MARC::DataField && field.tag =~ /^[^9]/ && field['0']
      field.subfields.each do |subfield|
        return true if subfield.code == '0' && subfield.value =~ /^\(uri\)/
      end
    end
    false
  end

  def bad_uri?(record)
    target_fields = record.fields('856')
    return false if target_fields.empty?
    target_fields.each do |field|
      next unless field['u']
      field.subfields.each do |subfield|
        next unless subfield.code == 'u'
        string = subfield.value
        return true unless URI.escape(URI.unescape(string).scrub) == string
      end
    end
    false
  end
end
