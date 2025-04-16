# frozen_string_literal: true

module MarcCleanup
  BLANK_REGEX = /^.*[[:blank:]]{2,}.*$|^.*[[:blank:]]+$|^[[:blank:]]+(.*)$/
  ### Remove non-numerical strings and append a new 020$q with the string
  def new_020_q(record)
    record.fields('020').each do |f020|
      f020.subfields.each do |subfield|
        next unless subfield.code == 'a'

        isbn_parts = /^\s*([\d-]+)\s*(\(.*?\))\s*$/.match(subfield.value)
        next if isbn_parts.nil?

        subfield.value = isbn_parts[1]
        f020.append(MARC::Subfield.new('q', isbn_parts[2]))
      end
    end
    record
  end

  ### Convert ISBN-10 to ISBN-13
  def isbn10_to_isbn13(isbn)
    stem = isbn[0..8]
    return nil if stem =~ /\D/

    existing_check = isbn[9]
    return nil if existing_check && existing_check != checkdigit_isbn10(stem)

    main = ISBN13PREFIX + stem
    checkdigit = checkdigit_isbn13(main)
    main + checkdigit
  end

  ### Calculate check digit for ISBN-10
  def checkdigit_isbn10(stem)
    int_sum = 0
    stem.each_char.with_index do |char, index|
      int_sum += char.to_i * (10 - index)
    end
    mod = (11 - (int_sum % 11)) % 11
    mod == 10 ? 'X' : mod.to_s
  end

  ### Calculate check digit for ISBN-13
  def checkdigit_isbn13(stem)
    int_sum = 0
    stem.each_char.with_index do |char, index|
      digit = char.to_i
      int_sum += index.even? ? digit : digit * 3
    end
    ((10 - (int_sum % 10)) % 10).to_s
  end

  ### Normalize ISBN-13
  def isbn13_normalize(raw_isbn)
    stem = raw_isbn[0..11]
    return nil if stem =~ /\D/

    checkdigit = checkdigit_isbn13(stem)
    if raw_isbn[12] && raw_isbn[12] != checkdigit
      nil
    else
      stem + checkdigit
    end
  end

  def initial_clean_isbn(isbn)
    isbn.delete('-')
        .delete('\\')
        .gsub(/\([^)]*\)/, '')
        .gsub(/^(.*)\$[cq].*$/, '\1')
        .gsub(/^\D+([0-9].*)$/, '\1')
  end

  def clean_isbn_13digit_vs_10digit(isbn)
    if isbn =~ /^978/
      isbn.gsub(/^(978[0-9 ]+).*$/, '\1')
          .delete(' ')
    else
      isbn.gsub(/([0-9])\s*([0-9]{4})\s*([0-9]{4})\s*([0-9xX]).*$/, '\1\2\3\4')
    end
  end

  def clean_isbn(isbn)
    new_isbn = initial_clean_isbn(isbn)
    new_isbn = clean_isbn_13digit_vs_10digit(new_isbn)
    new_isbn = new_isbn.gsub(/^([0-9]{9,13}[xX]?)[^0-9xX].*$/, '\1')
                       .gsub(/^([0-9]+?)\D.*$/, '\1')
    if new_isbn.length.between?(7, 8) && new_isbn =~ /^[0-9]+$/
      new_isbn.ljust(9, '0')
    else
      new_isbn
    end
  end

  ### Normalize any given string that is supposed to include an ISBN
  def isbn_normalize(isbn)
    return nil unless isbn

    clean_isbn = clean_isbn(isbn)
    valid_lengths = [9, 10, 12, 13] # ISBN10 and ISBN13 with/out check digits
    return nil unless valid_lengths.include? clean_isbn.length

    if clean_isbn.length < 12
      isbn10_to_isbn13(clean_isbn)
    else
      isbn13_normalize(clean_isbn)
    end
  end

  def modify_invalid_isbn_subfield(subfield)
    normalized_isbn = isbn_normalize(subfield.value)
    if normalized_isbn
      MARC::Subfield.new(subfield.code, normalized_isbn)
    else
      MARC::Subfield.new('z', subfield.value)
    end
  end

  ### If the ISBN is invalid, change the subfield code to z
  ### Otherwise, replace ISBN with normalized ISBN
  def move_invalid_isbn(record)
    record.fields('020').each do |field|
      field.subfields.each do |subfield|
        next unless subfield.code == 'a'

        new_subfield = modify_invalid_isbn_subfield(subfield)
        subfield.value = new_subfield.value
        subfield.code = new_subfield.code
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
    f042 = record.fields('042')
    return false if f042.empty?
    return true if f042.size > 1

    f042.first.subfields.each do |subfield|
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

  def extra_space_f880_f533(record)
    record.fields('880').select do |field|
      field['6'] =~ /^533/ &&
        field.subfields.any? do |subfield|
          subfield.code != '7' && subfield.value =~ BLANK_REGEX
        end
    end
  end

  def extra_space_f533(record)
    fields = record.fields('533').select do |field|
      field.subfields.any? do |subfield|
        subfield.code != '7' && subfield.value =~ BLANK_REGEX
      end
    end
    fields + extra_space_f880_f533(record)
  end

  def extra_space_f880_f76x_f830(record)
    record.fields('880').select do |field|
      field['6'] &&
        ('760'..'830').include?(field['6'][0..2]) &&
        field.subfields.any? do |subfield|
          subfield.code != '7' && subfield.value =~ BLANK_REGEX
        end
    end
  end

  def extra_space_f76x_f830(record)
    fields = record.fields('760'..'830').select do |field|
      field.subfields.any? do |subfield|
        !%w[w 7].include?(subfield.code) && subfield.value =~ BLANK_REGEX
      end
    end
    fields + extra_space_f880_f76x_f830(record)
  end

  def extra_space_f880_other_fields(record)
    tag_regex = /[1-469]..|0[2-9].|01[1-9]|7[0-5].|5[0-24-9].|53[0-24-9]/
    record.fields('880').select do |field|
      field['6'] &&
        field['6'][0..2] =~ tag_regex &&
        field.subfields.any? do |subfield|
          subfield.value =~ BLANK_REGEX
        end
    end
  end

  def extra_space_other_fields(record)
    tag_regex = /[1-469]..|0[2-9].|01[1-9]|7[0-5].|5[0-24-9].|53[0-24-9]/
    fields = record.fields.select do |field|
      field.tag =~ tag_regex &&
        field.subfields.any? do |subfield|
          subfield.value =~ BLANK_REGEX
        end
    end
    fields + extra_space_f880_other_fields(record)
  end

  def extra_spaces?(record)
    return true if extra_space_f533(record).size.positive?
    return true if extra_space_f76x_f830(record).size.positive?

    extra_space_other_fields(record).size.positive?
  end

  def extra_space_gsub(string)
    string.gsub!(/([[:blank:]]){2,}/, '\1')
    string.gsub!(/^(.*)[[:blank:]]+$/, '\1')
    string.gsub(/^[[:blank:]]+(.*)$/, '\1')
  end

  def extra_space_fix_field(field:, skip_subfields: [])
    field.subfields.each do |subfield|
      next if skip_subfields.include?(subfield.code)
      next unless subfield.value

      subfield.value = extra_space_gsub(subfield.value.dup)
    end
    field
  end

  ### Remove extra spaces from all fields that are not positionally defined
  def extra_space_fix(record)
    extra_space_f533(record).each do |field|
      extra_space_fix_field(field: field, skip_subfields: %w[7])
    end
    extra_space_f76x_f830(record).each do |field|
      extra_space_fix_field(field: field, skip_subfields: %w[w 7])
    end
    extra_space_other_fields(record).each do |field|
      extra_space_fix_field(field: field)
    end
    record
  end

  def multiple_no_040?(record)
    record.fields('040').size != 1
  end

  def multiple_no_040b?(record)
    return true if multiple_no_040?(record)

    f040b = record['040'].subfields.select { |subfield| subfield.code == 'b' }
    return true if f040b.size != 1

    f040b.first.value.match?(/^\s*$/)
  end

  def f046_errors?(record)
    subf_codes = %w[b c d e]
    subf_a_values = %w[r s p t x q n i k r m t x n]
    f046 = record.fields('046')
    f046.any? do |field|
      codes = field.subfields.map(&:code)
      field_a = field['a']
      (field_a && !subf_a_values.include?(field_a)) ||
        (field_a.to_s.empty? && (subf_codes & codes).size.positive?)
    end
  end

  def multiple_no_f245?(record)
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

  def f130_f240?(record)
    (%w[130 240] - record.tags).empty?
  end

  def multiple_1xx?(record)
    record.fields('100'..'199').size > 1
  end

  def relator_chars?(record)
    record.fields(%w[100 110 111 700 710 711]).any? do |field|
      relator_chars_target_subfields(field).select do |subfield|
        subfield.value =~ /[^a-z\-, .]/
      end.size.positive?
    end
  end

  def relator_chars_target_subfields(field)
    case field.tag
    when '111', '711'
      field.subfields.select { |subf| subf.code == 'j' }
    else
      field.subfields.select { |subf| subf.code == 'e' }
    end
  end

  def x00_subfq?(record)
    record.fields(%w[100 600 700 800]).any? do |field|
      field.subfields.select do |subfield|
        subfield.code == 'q' && subfield.value =~ /^[^(].*[^)]$/
      end.size.positive?
    end
  end

  def x00_subfd_no_comma?(record)
    record.fields(%w[100 600 700 800]).any? do |field|
      subf_d_index = field.subfields.index { |subfield| subfield.code == 'd' }
      next unless subf_d_index

      field.subfields[subf_d_index - 1].value =~ /[^,]$/
    end
  end

  def relator_comma?(record)
    record.fields(%w[100 110 111 700 710 711]).any? do |field|
      relator_index = relator_subfield_index(field)
      next unless relator_index

      field.subfields[relator_index - 1].value =~ /[^,]$/
    end
  end

  def relator_subfield_index(field)
    case field.tag
    when '111', '711'
      field.subfields.index { |subfield| subfield.code == 'j' }
    else
      field.subfields.index { |subfield| subfield.code == 'e' }
    end
  end

  def heading_end_punct?(record)
    punct_regex = /[^").!?-]$/
    record.fields(punctuated_heading_fields).any? do |field|
      next unless field.tag =~ /^[1678][0-5].$/

      last_heading_subfield = last_heading_subfield(field)
      next unless last_heading_subfield

      last_heading_subfield.value =~ punct_regex
    end
  end

  def punctuated_heading_fields
    %w[
      100 110 111 130
      600 610 611 630 650 651 654 655 656 657 658 662
      700 710 711 730 740 752 754
      800 810 811 830
    ]
  end

  def last_heading_subfield(field)
    regex = /[^02345]/
    heading_subfields = field.subfields.select do |subfield|
      subfield.code =~ regex
    end
    if heading_subfields.empty?
      nil
    else
      heading_subfields[-1]
    end
  end

  def subf_0_uri?(record)
    record.fields.any? do |field|
      field.instance_of?(MARC::DataField) &&
        field.tag =~ /^[^9]/ &&
        field.subfields.any? do |subfield|
          subfield.code == '0' && subfield.value =~ /^\(uri\)/
        end
    end
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

      field.subfields.delete_if { |subfield| subfield.value.to_s.empty? }
    end
    record.fields.delete_if { |field| field.instance_of?(MARC::DataField) && field.subfields.empty? }
    record
  end

  ### Remove the (uri) prefix from subfield 0s
  def subf_0_uri_fix(record)
    record.fields.each do |field|
      next unless field.instance_of?(MARC::DataField) && field.tag[0] != '9'

      field.subfields.each do |subfield|
        next unless subfield.code == '0'

        subfield.value = subfield.value.dup.delete_prefix('(uri)')
      end
    end
    record
  end

  ### Make the 040 $b 'eng' if it doesn't have a value
  def fix_040b(record)
    return record unless record.fields('040').size == 1

    f040 = record['040']
    return record if f040['b']

    field_index = record.fields.index(f040)
    subf_index = f040.subfields.index('a').to_i + 1
    subf_b = MARC::Subfield.new('b', 'eng')
    record.fields[field_index].subfields.insert(subf_index, subf_b)
    record
  end

  def split_f041_subfield(subfield)
    subfields = []
    if (subfield.value.size % 3).zero?
      subfield.value.scan(/.../).each do |language|
        subfields.append(MARC::Subfield.new(subfield.code, language))
      end
    else
      subfields.append(MARC::Subfield.new(subfield.code, subfield.value))
    end
    subfields
  end

  def split_f041_field(field)
    new_field = MARC::DataField.new('041', field.indicator1, field.indicator2)
    field.subfields.each do |subfield|
      new_subfields = split_f041_subfield(subfield)
      new_subfields.each { |new_subfield| new_field.append(new_subfield) }
    end
    new_field
  end

  ### Split up subfields that contain multiple 3-letter language codes
  def fix_f041(record)
    f041 = record.fields('041')
    f041.each do |field|
      f_index = record.fields.index(field)
      new_field = split_f041_field(field)
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
  ### Example order_array: ['a', 'b', 'c']
  def subfield_sort(record:, target_tags:, order_array: nil)
    record.fields(target_tags).each do |field|
      next if field.instance_of?(MARC::ControlField)

      order_array ||= field.subfields.map(&:code).uniq.sort
      new_subfields = sort_listed_subfields(field: field, order_array: order_array)
      new_subfields += find_unlisted_subfields(field: field, order_array: order_array)
      field.subfields = new_subfields
    end
    record
  end

  def find_unlisted_subfields(field:, order_array:)
    field.subfields.reject do |subfield|
      order_array.include?(subfield.code)
    end
  end

  def sort_listed_subfields(field:, order_array:)
    listed_subfields = field.subfields.select do |subfield|
      order_array.include?(subfield.code)
    end
    listed_subfields.sort_by! do |subfield|
      order_array.index { |code| code == subfield.code }
    end
  end
end
