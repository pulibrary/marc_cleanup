# frozen_string_literal: true

### Error detection and fixes related to paired fields
module MarcCleanup
  ### Scenario 1: $6 value contains spaces in 880 field or variable field:
  ###   Remove all space characters [extra_space_fix]
  ### Scenario 2: One 264 field exists with $6, and one 880 field with $6 260:
  ###   Change $6 value in 880 to 264 [fix_f880_26x]
  ### Scenario 3: One 260 field exists, and one 880 field with $6 264:
  ###   Change $6 value in 880 to 260 [fix_f880_26x]
  ### Scenario 4: Variable field has $6, and there is no corresponding 880 with the field tag:
  ###   Remove $6 value in variable field [fix_f880_subf6_variable_fields]
  ### Scenario 5: One 880 field has $6 for a tag, and there is one corresponding variable field with no $6:
  ###   Add $6 value to variable field [fix_f880_subf6_paired_fields]
  ### Scenario 6: 880 field has a tag in $6 that is not represented in a variable field:
  ###   Change sequence number to '00' to make it an unlinked 880 [fix_unlinked_f880]
  ### Scenario 7: One $6 per tag in non-880 fields, and one $6 per tag in 880 fields:
  ###   Reorder sequence of 880s; if there is a $6 in a variable field and no corresponding 880, reserve
  ###   that field sequence for the variable field [resequence_f880_pairs]
  def fix_f880(record)
    extra_space_fix(record)
    fix_f880_26x(record)
    fix_f880_subf6_variable_fields(record)
    fix_f880_subf6_paired_fields(record)
    fix_unlinked_f880(record)
    resequence_f880_pairs(record)
    record
  end

  def fix_f880_26x(record)
    return record if blocked_f880_26x?(record)

    f880_26x = record.fields('880').find { |field| field['6'] =~ /^26[04]/ }
    extra_subf6_info = subf6_info(f880_26x)
    f26x_info = f26x_info(record)
    fix_f880_26x_linked_field(f880_26x, f26x_info, extra_subf6_info)
    record
  end

  def fix_f880_26x_linked_field(field, f26x_info, extra_subf6_info)
    field.indicator2 = f26x_info[:indicator2]
    field.subfields.find do |subfield|
      subfield.code == '6'
    end.value = "#{f26x_info[:tag]}-#{extra_subf6_info[:sequence_number]}#{extra_subf6_info[:char_info]}"
  end

  def f26x_info(record)
    field = record.fields(%w[260 264]).find { |field| field['6'] =~ /^880/ }
    {
      tag: field.tag,
      indicator2: field.indicator2
    }
  end

  def blocked_f880_26x?(record)
    f26x = record.fields(%w[260 264]).select { |field| field['6'] =~ /^880/ }
    f880_26x = record.fields('880').select { |field| field['6'] =~ /^26[04]/ }
    f26x.size != 1 || f880_26x.size != 1
  end

  def fix_f880_subf6_variable_fields(record)
    linked_field_subf6 = linked_field_pairings(record).map { |tag| tag[0..2] }.uniq
    f880_subf6 = f880_pairings(record).map { |tag| tag[0..2] }.uniq
    unmatched_variable_subf6 = linked_field_subf6 - f880_subf6
    unmatched_variable_subf6.each do |tag|
      remove_subf6_per_tag(tag, record)
    end
    record
  end

  def remove_subf6_per_tag(tag, record)
    record.fields(tag).each do |field|
      field.subfields.delete_if { |subfield| subfield.code == '6' }
    end
  end

  def fix_f880_subf6_paired_fields(record)
    linked_field_subf6 = linked_field_pairings(record).map { |tag| tag[0..2] }.uniq
    f880_subf6 = f880_pairings(record).map { |tag| tag[0..2] }.uniq
    (f880_subf6 - linked_field_subf6).each do |tag|
      fix_unmatched_paired_tag(record, tag)
    end
    record
  end

  def blocked_unmatched_pair?(record, tag)
    paired_fields = record.fields('880').select { |field| field['6'] =~ /^#{tag}/ }
    paired_fields.size != 1 || record.fields(tag).size != 1
  end

  def fix_unmatched_paired_tag(record, tag)
    return if blocked_unmatched_pair?(record, tag)

    paired_field = record.fields('880').find { |field| field['6'] =~ /^#{tag}/ }
    sequence_number = paired_field['6'].gsub(/^#{tag}-([0-9]{2}).*/, '\1')
    record.fields.find do |field|
      field.tag == tag
    end.subfields << MARC::Subfield.new('6', "880-#{sequence_number}")
  end

  def fix_unlinked_f880(record)
    linked_field_tags = record.fields(LINKED_FIELD_TAGS).map(&:tag).uniq
    f880_subf6 = f880_pairings(record).map { |tag| tag[0..2] }.uniq
    unmatched_paired_subf6 = f880_subf6 - linked_field_tags
    unmatched_paired_subf6.each do |tag|
      fix_unmatched_f880_subf6(tag, record)
    end
    record
  end

  def fix_unmatched_f880_subf6(tag, record)
    record.fields('880').select { |field| field['6'] =~ /^#{tag}/ }.each do |field|
      field.subfields.find do |subfield|
        subfield.code == '6'
      end.value = field['6'].gsub(/^([0-9]+)-[0-9]+([^0-9]*.*)$/, '\1-00\2')
    end
  end

  def subf6_info(field)
    {
      sequence_number: field['6'].gsub(/^.*-([0-9]+)[^0-9]*.*$/, '\1'),
      char_info: field['6'].gsub(/^.*-[0-9]+([^0-9]*.*)$/, '\1')
    }
  end

  def resequence_f880_pairs(record)
    return record if blocked_f880_resequence?(record)

    linked_fields = linked_field_pairings(record).sort.group_by { |tag| tag[0..2] }
    linked_fields.keys.each_with_index do |tag, index|
      resequence_field_tag(sequence: format('%02d', index + 1), tag: tag, record: record)
    end
    record
  end

  def resequence_field_tag(sequence:, tag:, record:)
    f880 = record.fields(tag).find { |field| field['6'] }
    f880.subfields.find { |subfield| subfield.code == '6' }.value = "880-#{sequence}"
    resequence_paired_field(sequence, tag, record)
  end

  def resequence_paired_field(sequence, tag, record)
    paired_field = record.fields('880').find { |field| field['6'] =~ /#{tag}-(?!00)/ }
    return unless paired_field

    paired_field.subfields.find { |subfield| subfield.code == '6' }
                .value = "#{tag}-#{sequence}#{subf6_info(paired_field)[:char_info]}"
  end

  def blocked_f880_resequence?(record)
    f880_pairings(record).group_by { |tag| tag[0..2] }.any? { |_tag, fields| fields.size > 1 } ||
      linked_field_pairings(record).group_by { |tag| tag[0..2] }.any? { |_tag, fields| fields.size > 1 }
  end

  def orphan_linked_fields(record)
    {
      orphan_f880: f880_pairings(record) - linked_field_pairings(record),
      orphan_linked_field: linked_field_pairings(record) - f880_pairings(record)
    }
  end

  def duplicate_subf6(record)
    {
      duplicate_f880_subf6: f880_pairings(record).tally.select { |_tag, count| count > 1 }.keys,
      duplicate_linked_field_subf6: linked_field_pairings(record).tally.select { |_tag, count| count > 1 }.keys
    }
  end

  def subf6_spaces(record)
    {
      f880_subf6_spaces: record.fields('880').select { |field| field['6'] =~ /\s/ },
      linked_field_subf6_spaces: record.fields(LINKED_FIELD_TAGS).select { |field| field['6'] =~ /\s/ }
    }
  end

  def pair_880_errors(record)
    hash = { f880_no_subf6: record.fields('880').select { |field| field['6'].nil? } }
    hash.merge!(orphan_linked_fields(record))
    hash.merge!(duplicate_subf6(record))
    hash.merge(subf6_spaces(record))
  end

  def f880_pairings(record)
    target_fields = record.fields('880').select { |field| field['6'] }
    target_fields.reject! { |field| field['6'] =~ /-00/ }
    target_fields.map do |field|
      field['6'].gsub(/^[^0-9]*([0-9]{3}-[0-9]{2}).*$/, '\1')
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
end
