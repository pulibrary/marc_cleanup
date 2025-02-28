# frozen_string_literal: true

module MarcCleanup
  ### Remove non-numerical strings and append a new 020$q with the string
  def new_020_q(record)
    record.fields('020').each do |f020|
      f020.subfields.each do |subfield|
        next unless subfield.code == 'a'
        isbn_parts = /^\s*([\d\-]+)\s*(\(.*?\))\s*$/.match(subfield.value)
        next if isbn_parts.nil?
        subfield.value = isbn_parts[1]
        f020.append(MARC::Subfield.new('q', isbn_parts[2]))
      end
    end
    record
  end

  ### Convert ISBN-10 to ISBN-13
  def isbn10_to_13(isbn)
    stem = isbn[0..8]
    return nil if stem =~ /\D/

    existing_check = isbn[9]
    return nil if existing_check && existing_check != checkdigit_10(stem)

    main = ISBN13PREFIX + stem
    checkdigit = checkdigit_13(main)
    main + checkdigit
  end

  ### Calculate check digit for ISBN-10
  def checkdigit_10(stem)
    int_index = 0
    int_sum = 0
    stem.each_char do |digit|
      int_sum += digit.to_i * (10 - int_index)
      int_index += 1
    end
    mod = (11 - (int_sum % 11)) % 11
    mod == 10 ? 'X' : mod.to_s
  end

  ### Calculate check digit for ISBN-13
  def checkdigit_13(stem)
    int_index = 0
    int_sum = 0
    stem.each_char do |digit|
      int_sum += int_index.even? ? digit.to_i : digit.to_i * 3
      int_index += 1
    end
    ((10 - (int_sum % 10)) % 10).to_s
  end

  ### Normalize ISBN-13
  def isbn13_normalize(raw_isbn)
    int_sum = 0
    stem = raw_isbn[0..11]
    return nil if stem =~ /\D/

    int_index = 0
    stem.each_char do |digit|
      int_sum += int_index.even? ? digit.to_i : digit.to_i * 3
      int_index += 1
    end
    checkdigit = checkdigit_13(stem)
    return nil if raw_isbn[12] && raw_isbn[12] != checkdigit

    stem + checkdigit
  end

  ### Normalize any given string that is supposed to include an ISBN
  def isbn_normalize(isbn)
    return nil unless isbn

    raw_isbn = isbn.dup
    raw_isbn.delete!('-')
    raw_isbn.delete!('\\')
    raw_isbn.gsub!(/\([^\)]*\)/, '')
    raw_isbn.gsub!(/^(.*)\$c.*$/, '\1')
    raw_isbn.gsub!(/^(.*)\$q.*$/, '\1')
    raw_isbn.gsub!(/^\D+([0-9].*)$/, '\1')
    if raw_isbn =~ /^978/
      raw_isbn.gsub!(/^(978[0-9 ]+).*$/, '\1')
      raw_isbn.delete!(' ')
    else
      raw_isbn.gsub!(/([0-9])\s*([0-9]{4})\s*([0-9]{4})\s*([0-9xX]).*$/, '\1\2\3\4')
    end
    raw_isbn.gsub!(/^([0-9]{9,13}[xX]?)[^0-9xX].*$/, '\1')
    raw_isbn.gsub!(/^([0-9]+?)\D.*$/, '\1')
    if raw_isbn.length > 6 && raw_isbn.length < 9 && raw_isbn =~ /^[0-9]+$/
      raw_isbn = raw_isbn.ljust(9, '0')
    end
    valid_lengths = [9, 10, 12, 13] # ISBN10 and ISBN13 with/out check digits
    return nil unless valid_lengths.include? raw_isbn.length

    if raw_isbn.length < 12
      isbn10_to_13(raw_isbn)
    else
      isbn13_normalize(raw_isbn)
    end
  end

  ### If the ISBN is invalid, change the subfield code to z
  ### Otherwise, replace ISBN with normalized ISBN
  def move_invalid_isbn(record)
    record.fields('020').each do |f020|
      f020.subfields.each do |subfield|
        next unless subfield.code == 'a'
        isbn = subfield.value
        normalized_isbn = isbn_normalize(isbn)
        if normalized_isbn
          subfield.value = normalized_isbn
        else
          subfield.code = 'z'
        end
      end
    end
    record
  end

  # check the 041 field for errors
  # 041 is a language code
  def f041_errors?(record)
    f041 = record.fields('041')
    return false if f041.empty?

    f041.each do |field|
      field.subfields.each do |subfield|
        val = subfield.value
        return true if (val.size > 3) && (val.size % 3).zero?
      end
    end
    false
  end

  # http://www.loc.gov/standards/valuelist/marcauthen.html
  def auth_codes_f042
    %w[
      anuc croatica dc dhca dlr
      gamma gils gnd1 gnd2 gnd3 gnd4 gnd5 gnd6 gnd7 gndz isds/c issnuk
      lacderived lc lcac lccopycat lccopycat-nm lcd lcderive
      lchlas lcllh lcnccp lcnitrate lcnuc lcode
      msc natgaz nbr nlc nlmcopyc norbibl nsdp nst ntccf nznb
      pcc premarc reveal sanb scipio toknb
      ukblcatcopy ukblderived ukblproject ukblsr ukscp
      xisds/c xissnuk xlc xnlc xnsdp
    ]
  end

  def auth_code_error?(record)
    return false unless record['042']
    return true if record.fields('042').size > 1

    record['042'].subfields.each do |subfield|
      next if subfield.code != 'a'
      return true unless auth_codes_f042.include?(subfield.value)
    end
    false
  end

  def empty_subfields?(record)
    record.fields.each do |field|
      next unless field.instance_of?(MARC::DataField)

      field.subfields.each do |subfield|
        return true if subfield.value =~ /^[[:blank:]]*$/
      end
    end
    false
  end

  def extra_spaces?(record)
    blank_regex = /^.*[[:blank:]]{2,}.*$|^.*[[:blank:]]+$|^[[:blank:]]+(.*)$/
    record.fields.each do |field|
      next unless field.instance_of?(MARC::DataField) && field.tag != '010'

      case field.tag
      when /[1-469]..|0[2-9].|01[1-9]|7[0-5].|5[0-24-9].|53[0-24-9]/
        field.subfields.each do |subfield|
          return true if subfield.value =~ blank_regex
        end
      when '533'
        field.subfields.each do |subfield|
          next if subfield.code == '7'

          return true if subfield.value =~ blank_regex
        end
      when /7[6-8]./
        field.subfields.each do |subfield|
          next unless subfield.code =~ /[a-v3-8]/

          return true if subfield.value =~ blank_regex
        end
      when /8../
        field.subfields.each do |subfield|
          next unless subfield.code =~ /[^w7]/

          return true if subfield.value =~ blank_regex
        end
      end
    end
    false
  end

  def extra_space_gsub(string)
    string.gsub!(/([[:blank:]]){2,}/, '\1')
    string.gsub!(/^(.*)[[:blank:]]+$/, '\1')
    string.gsub(/^[[:blank:]]+(.*)$/, '\1')
  end

  ### Remove extra spaces from all fields that are not positionally defined
  def extra_space_fix(record)
    record.fields.each do |field|
      next unless field.instance_of?(MARC::DataField) && field.tag != '010'

      case field.tag
      when /^[1-469]..|0[2-9].|01[1-9]|7[0-5].|5[0-24-9].|53[0-24-9]/
        field.subfields.each do |subfield|
          next if subfield.value.nil?

          subfield.value = extra_space_gsub(subfield.value.dup)
        end
      when '533'
        field.subfields.each do |subfield|
          next if subfield.code == '7' || subfield.value.nil?

          subfield.value = extra_space_gsub(subfield.value.dup)
        end
      when /^7[6-8]./
        field.subfields.each do |subfield|
          next if subfield.code =~ /[^a-v3-8]/ || subfield.value.nil?

          subfield.value = extra_space_gsub(subfield.value.dup)
        end
      when /^8../
        field.subfields.each do |subfield|
          next if %w[w 7].include?(subfield.code) || subfield.value.nil?

          subfield.value = extra_space_gsub(subfield.value.dup)
        end
      end
    end
    record
  end

  def multiple_no_040?(record)
    record.fields('040').size != 1
  end

  def multiple_no_040b?(record)
    f040 = record.fields('040')
    return true if f040.size != 1

    f040 = f040.first
    b040 = f040.subfields.select { |subfield| subfield.code == 'b' }
    return true if b040.size != 1

    b040.first.value.match?(/^\s*$/)
  end

  def f046_errors?(record)
    subf_codes = %w[b c d e]
    subf_a_values = %w[r s p t x q n i k r m t x n]
    f046 = record.fields('046')
    return false if f046.empty?

    f046.each do |field|
      codes = field.subfields.map(&:code)
      return true if field['a'] && !subf_a_values.include?(field['a'])
      return true if field['a'].nil? && (subf_codes & codes).size.positive?
    end
    false
  end

  def multiple_no_245?(record)
    record.fields('245').size != 1
  end

  def missing_040c?(record)
    return true unless record['040'] && record['040']['c']

    false
  end

  def pair_880_errors?(record)
    return true if record.fields('880').select { |field| field['6'].nil? }.size.positive?

    pair_880s = f880_pairings(record)
    linked_fields = linked_field_pairings(record)
    pair_880s.uniq != pair_880s || pair_880s.uniq.sort != linked_fields.uniq.sort
  end

  def f880_pairings(record)
    target_fields = record.fields('880').select do |field|
      field['6'] =~ /^[0-9]{3}-[0-9][1-9]/
    end
    target_fields.map do |field|
      field['6'].gsub(/^([0-9]{3}-[0-9]{2}).*$/, '\1')
    end
  end

  def linked_field_pairings(record)
    target_fields = record.fields('010'..'899').select do |field|
      field.tag != '880' && field['6']
    end
    target_fields.map do |field|
      "#{field.tag}-#{field['6'].gsub(/^880-([0-9]{2}).*$/, '\1')}"
    end
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
      next unless field.instance_of?(MARC::DataField) && field.tag =~ /^[^9]/ && field['0']

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

  ### Normalize to the NFC (combined) form of diacritics for characters with
  #     Arabic diacritics; normalize to NFD for characters below U+622 and
  #     between U+1E00 and U+2A28
  def composed_chars_normalize(record)
    record.fields.each do |field|
      next unless field.class == MARC::DataField

      field_index = record.fields.index(field)
      curr_subfield = 0
      field.subfields.each do |subfield|
        prevalue = subfield.value
        if prevalue =~ /^.*[\u0653\u0654\u0655].*$/
          prevalue = prevalue.unicode_normalize(:nfc)
        end
        fixed_subfield = prevalue.codepoints.map do |codepoint|
          char = codepoint.chr(Encoding::UTF_8)
          char.unicode_normalize!(:nfd) if codepoint < 1570 || (7_680..10_792).cover?(codepoint)
          char
        end.join
        record.fields[field_index].subfields[curr_subfield].value = fixed_subfield
        curr_subfield += 1
      end
    end
    record
  end

  ### Replace empty indicators with a space;
  ###   scrub indicators with bad UTF-8;
  ###   The ruby-marc gem converts nil subfields to spaces
  def empty_indicator_fix(record)
    record.fields.each do |field|
      next unless field.instance_of?(MARC::DataField)

      ind1_value = field.indicator1.dup
      ind1_value.scrub!('')
      field.indicator1 = ' ' if ind1_value.empty?
      ind2_value = field.indicator2.dup
      ind2_value.scrub!('')
      field.indicator2 = ' ' if ind2_value.empty?
    end
    record
  end

  ### Remove empty subfields from DataFields
  def empty_subfield_fix(record)
    record.fields.each do |field|
      next unless field.instance_of?(MARC::DataField)

      field.subfields.delete_if { |subfield| subfield.value.nil? || subfield.value.empty? }
    end
    record.fields.delete_if { |field| field.instance_of?(MARC::DataField) && field.subfields.empty? }
    record
  end

  ### Remove the (uri) prefix from subfield 0s
  def subf_0_uri_fix(record)
    record.fields.each do |field|
      next unless field.instance_of?(MARC::DataField) && field.tag[0] != '9' && field['0']

      field.subfields.each do |subfield|
        next unless subfield.code == '0' && subfield.value =~ /^\(uri\)/

        subfield.value = subfield.value.dup.delete_prefix('(uri)')
      end
    end
    record
  end

  ### Escape URIs
  def uri_escape(record)
    target_fields = record.fields('856')
    return record if target_fields.empty?

    fixed_record = record
    target_fields.each do |field|
      next unless field['u']

      field_index = fixed_record.fields.index(field)
      field.subfields.each do |subfield|
        next unless subfield.code == 'u'

        subfield_index = field.subfields.index(subfield)
        string = subfield.value
        fixed_string = URI.escape(URI.unescape(string).scrub)
        fixed_record.fields[field_index].subfields[subfield_index].value = fixed_string
      end
    end
    fixed_record
  end

  ### Make the 040 $b 'eng' if it doesn't have a value
  def fix_040b(record)
    return record unless record.fields('040').size == 1

    f040 = record['040']
    field_index = record.fields.index(f040)
    b040 = f040.subfields.select { |subfield| subfield.code == 'b' }
    return record unless b040.empty?

    subf_codes = f040.subfields.map(&:code)
    subf_index = if f040['a']
                   (subf_codes.index { |i| i == 'a' }) + 1
                 else
                   0
                 end
    subf_b = MARC::Subfield.new('b', 'eng')
    record.fields[field_index].subfields.insert(subf_index, subf_b)
    record
  end

  ### Split up subfields that contain multiple 3-letter language codes
  def fix_f041(record)
    f041 = record.fields('041')
    return record if f041.empty?

    f041.each do |field|
      f_index = record.fields.index(field)
      new_field = MARC::DataField.new('041', field.indicator1, field.indicator2)
      field.subfields.each do |subfield|
        code = subfield.code
        val = subfield.value
        if (val.size % 3).zero?
          langs = val.scan(/.../)
          langs.each do |lang|
            new_field.append(MARC::Subfield.new(code, lang))
          end
        else
          new_field.append(MARC::Subfield.new(code, val))
        end
      end
      record.fields[f_index] = new_field
    end
    record
  end

  ### Removes text from the beginning of a subfield
  ### An array of hashes of the format { field:, subfields: } will be passed
  ###   in the targets: symbol
  ###   subfield: is an array of subfield codes
  def remove_prefix_from_subfield(record:, targets:, string:)
    targets.each do |target|
      record.fields(target[:field]).each do |field|
        field.subfields.each do |subfield|
          next unless target[:subfields].include?(subfield.code)

          subfield.value = subfield.value.dup.delete_prefix(string)
        end
      end
    end
    record
  end

  ### Adds text to the beginning of a subfield
  ### An array of hashes of the format { field:, subfields: } will be passed
  ###   in the targets: symbol
  ###   subfield: is an array of subfield codes
  def add_prefix_to_subfield(record:, targets:, string:)
    targets.each do |target|
      record.fields(target[:field]).each do |field|
        field.subfields.each do |subfield|
          next unless target[:subfields].include?(subfield.code)

          subfield.value = subfield.value.dup.prepend(string)
        end
      end
    end
    record
  end

  ### Sort subfields for target fields with an arbitrary order
  def subfield_sort(record, target_tags, order_array = nil)
    target_fields = record.fields.select { |f| target_tags.include?(f.tag) }
    return record if target_fields.empty?

    target_fields.each do |field|
      next unless field.class == MARC::DataField

      orig_codes = field.subfields.map { |subfield| subfield.code }.uniq.sort
      order_array = orig_codes if order_array.nil?
      new_subfields = []
      order_array.each do |code|
        next unless orig_codes.include?(code)

        target_subf = field.subfields.select { |subfield| subfield.code == code }
        target_subf.each { |subfield| new_subfields << subfield }
      end
      rem_subfields = field.subfields.select { |subf| !order_array.include?(subf.code) }
      rem_subfields.each do |subfield|
        new_subfields << subfield
      end
      field.subfields = new_subfields
    end
    record
  end
end
