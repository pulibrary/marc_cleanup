module MarcCleanup
  def blvl_ab_valid?(record)
    record['773'] ? true : false
  end

  def ftype_ac_cdm_valid?(record)
    present_fields1 = record.fields(
      %w[
          020
          024
          027
          088
          100
          110
          111
          300
          533
          700
          710
          711
          800
          810
          811
          830
      ]
    )
    present_fields2 = record.fields(%w[260 264 533])
    return false if present_fields1.empty?
    return false if present_fields2.empty?
    f1_criteria = false
    present_fields1.each do |field|
      f1_criteria = true if field['a']
    end
    present_fields2.each do |field|
      case field.tag
      when '260'
        return true if field['a'] || field['b']
      when '264'
        return true if field['b']
      when '533'
        return true if field['c']
      end
    end
    false
  end

  def ftype_ac_is_valid?(record)
    present_fields = record.fields(%w[260 264 533])
    return false if present_fields.empty?
    present_fields.each do |field|
      case field.tag
      when '260'
        return true if field['a'] || field['b']
      when '264'
        return true if field['b']
      when '533'
        return true if field['c']
      end
    end
    false
  end

  def ftype_dt_cdm_valid?(record)
    present_fields = record.fields(
      %w[
          020
          024
          027
          028
          088
          100
          110
          111
          300
          533
          700
          710
          711
          800
          810
          811
          830
      ]
    )
    return false if present_fields.empty?
    present_fields.each do |field|
      case field.tag
      when '300'
        return true if field['a'] || field['f']
      when '533'
        return true if field['e']
      else
        return true if field['a']
      end
    end
    false
  end

  def ftype_e_cdims_valid?(record)
    present_fields1 = record.fields(%w[007 300 338])
    present_fields2 = record.fields(%w[260 264 533])
    return false if present_fields1.empty?
    return false if present_fields2.empty?
    f1_criteria = false
    present_fields1.each do |field|
      case field.tag
      when '007'
        f1_criteria = true if %w[a d r].include? field.value[0]
      when '300'
        f1_criteria = true if field['a']
      when '338'
        f1_criteria = true if field['a'] || field['b']
      when 533
        f1_criteria = true if field['e']
      end
    end
    return false unless f1_criteria
    present_fields2.each do |field|
      case field.tag
      when '260'
        return true if field['a'] || field['b']
      when '264'
        return true if field['b']
      when '533'
        return true if field['c']
      end
    end
    false
  end

  def ftype_f_cdm_valid?(record)
    present_fields = record.fields(
      %w[
          007
          300
          338
          533
      ]
    )
    return false if present_fields.empty?
    present_fields.each do |field|
      case field.tag
      when '007'
        return true if %w[a d r].include? field.value[0]
      when '300'
        return true if field['a'] || field['f']
      when '338'
        return true if field['a'] || field['b']
      when 533
        return true if field['e']
      end
    end
    false
  end

  def ftype_g_cdm_valid?(record)
    present_fields = record.fields(
      %w[
          007
          008
          300
          338
          345
          346
          538
      ]
    )
    return false if present_fields.empty?
    present_fields.each do |field|
      case field.tag
      when '007'
        return true if %w[a d r].include? field.value[0]
      when '008'
        return true if %w[g k o r].include?(record.leader[6]) && %w[f m p s t v].include?(field.value[33])
      when '300'
        return true if field['a']
      when '345'
        return true
      when '346'
        return true
      when '538'
        return true if field['a']
      end
    end
    false
  end

  def ftype_g_is_valid?(record)
    present_fields1 = record.fields(
      %w[
          007
          008
          300
          338
          345
          346
          538
      ]
    )
    present_fields2 = record.fields(%w[260 264 533])
    return false if present_fields1.empty?
    return false if present_fields2.empty?
    f1_criteria = false
    present_fields1.each do |field|
      case field.tag
      when '007'
        f1_criteria = true if %w[g m v].include? field.value[0]
      when '008'
        f1_criteria = true if %w[g k o r].include?(record.leader[6]) && %w[f m p s t v].include?(field.value[33])
      when '300'
        f1_criteria = true if field['a']
      when '338'
        f1_criteria = true if field['a'] || field['b']
      when '345'
        f1_criteria = true
      when '346'
        f1_criteria = true
      when 538
        f1_criteria = true if field['a']
      end
    end
    return false unless f1_criteria
    present_fields2.each do |field|
      case field.tag
      when '260'
        return true if field['a'] || field['b']
      when '264'
        return true if field['b']
      when '533'
        return true if field['c']
      end
    end
    false
  end

  def ftype_ij_cdm_valid?(record)
    present_fields = record.fields(
      %w[
          007
          300
          338
          344
          538
      ]
    )
    return false if present_fields.empty?
    present_fields.each do |field|
      case field.tag
      when '007'
        return true if field.value[0] == 's'
      when '300'
        return true if field['a']
      when '338'
        return true if field['a'] || field['b']
      when '344'
        return true
      when '538'
        return true if field['a']
      end
    end
    false
  end

  def ftype_ij_is_valid?(record)
    present_fields1 = record.fields(
      %w[
          007
          300
          338
          344
          538
      ]
    )
    present_fields2 = record.fields(%w[260 264 533])
    return false if present_fields1.empty?
    return false if present_fields2.empty?
    f1_criteria = false
    present_fields1.each do |field|
      case field.tag
      when '007'
        f1_criteria = true if field.value[0] == 's'
      when '300'
        f1_criteria = true if field['a']
      when '338'
        f1_criteria = true if field['a'] || field['b']
      when '344'
        f1_criteria = true
      when 538
        f1_criteria = true if field['a']
      end
    end
    return false unless f1_criteria
    present_fields2.each do |field|
      case field.tag
      when '260'
        return true if field['a'] || field['b']
      when '264'
        return true if field['b']
      when '533'
        return true if field['c']
      end
    end
    false
  end

  def ftype_k_cdm_valid?(record)
    present_fields = record.fields(
      %w[
          007
          008
          300
          338
      ]
    )
    return false if present_fields.empty?
    present_fields.each do |field|
      case field.tag
      when '007'
        return true if field.value[0] == 'k'
      when '008'
        return true if %w[g k o r].include?(record.leader[6]) && %w[a c k l n o p].include?(field.value[33])
      when '300'
        return true if field['a']
      when '338'
        return true if field['a'] || field['b']
      end
    end
    false
  end

  def ftype_k_is_valid?(record)
    present_fields1 = record.fields(
      %w[
          007
          008
          300
          338
      ]
    )
    present_fields2 = record.fields(%w[260 264 533])
    return false if present_fields1.empty?
    return false if present_fields2.empty?
    f1_criteria = false
    present_fields1.each do |field|
      case field.tag
      when '007'
        f1_criteria = true if field.value[0] == 'k'
      when '008'
        return true if %w[g k o r].include?(record.leader[6]) && %w[a c k l n o p].include?(field.value[33])
      when '300'
        f1_criteria = true if field['a']
      when '338'
        f1_criteria = true if field['a'] || field['b']
      end
    end
    return false unless f1_criteria
    present_fields2.each do |field|
      case field.tag
      when '260'
        return true if field['a'] || field['b']
      when '264'
        return true if field['b']
      when '533'
        return true if field['c']
      end
    end
    false
  end

  def ftype_m_cdm_valid?(record)
    present_fields = record.fields(
      %w[
        007
        300
        338
        347
        538
      ]
    )
    return false if present_fields.empty?
    present_fields.each do |field|
      case field.tag
      when '007'
        return true if field.value[0] == 'c'
      when '300'
        return true if field['a']
      when '338'
        return true if field['a'] || field['b']
      when '347'
        return true
      when '538'
        return true if field['a']
      end
    end
    false
  end

  def ftype_m_is_valid?(record)
    present_fields1 = record.fields(
      %w[
          007
          300
          338
          347
          538
      ]
    )
    present_fields2 = record.fields(%w[260 264 533])
    return false if present_fields1.empty?
    return false if present_fields2.empty?
    f1_criteria = false
    present_fields1.each do |field|
      case field.tag
      when '007'
        f1_criteria = true if field.value[0] == 'c'
      when '300'
        f1_criteria = true if field['a']
      when '338'
        f1_criteria = true if field['a'] || field['b']
      when '347'
        f1_criteria = true
      when '538'
        f1_criteria = true if field['a']
      end
    end
    return false unless f1_criteria
    present_fields2.each do |field|
      case field.tag
      when '260'
        return true if field['a'] || field['b']
      when '264'
        return true if field['b']
      when '533'
        return true if field['c']
      end
    end
    false
  end

  def ftype_or_cdm_valid?(record)
    present_fields = record.fields(
      %w[
          008
          300
          338
      ]
    )
    return false if present_fields.empty?
    present_fields.each do |field|
      case field.tag
      when '008'
        return true if %w[g k o r].include?(record.leader[6]) && %w[a b c d g q r w].include?(field.value[33])
      when '300'
        return true if field['a']
      when '338'
        return true if field['a'] || field['b']
      end
    end
    false
  end

  def ftype_or_is_valid?(record)
    present_fields1 = record.fields(
      %w[
          008
          300
          338
      ]
    )
    present_fields2 = record.fields(%w[260 264 533])
    return false if present_fields1.empty?
    return false if present_fields2.empty?
    f1_criteria = false
    present_fields1.each do |field|
      case field.tag
      when '008'
        return true if %w[g k o r].include?(record.leader[6]) && %w[a b c d g q r w].include?(field.value[33])
      when '300'
        f1_criteria = true if field['a']
      when '338'
        f1_criteria = true if field['a'] || field['b']
      end
    end
    return false unless f1_criteria
    present_fields2.each do |field|
      case field.tag
      when '260'
        return true if field['a'] || field['b']
      when '264'
        return true if field['b']
      when '533'
        return true if field['c']
      end
    end
    false
  end

  def ftype_p_cd_valid?(record)
    present_fields = record.fields(
      %w[
          100
          110
          111
          300
          338
          700
          710
          711
      ]
    )
    return false if present_fields.empty?
    present_fields.each do |field|
      case field.tag
      when '300'
        return true if field['a'] || field['f']
      when '338'
        return true if field['a'] || field['b']
      else
        return true if field['a']
      end
    end
    false
  end

  def sparse_record?(record)
    type = record.leader[6]
    blvl = record.leader[7]
    form = bib_form(record)
    return true unless %w[\  a b c d f o q r s].include?(form)
    f245 = record['245']
    return true unless f245 && (f245['a'] || f245['k'])
    return true unless record['008']
    valid =
      if %w[a b].include?(blvl)
        blvl_ab_valid?(record)
      elsif %w[a c].include?(type) && %w[c d m].include?(blvl)
        ftype_ac_cdm_valid?(record)
      elsif %w[a c].include?(type) && %w[i s].include?(blvl)
        ftype_ac_is_valid?(record)
      elsif %w[d t].include?(type) && %w[c d m].include?(blvl)
        ftype_dt_cdm_valid?(record)
      elsif %w[e].include?(type) && %w[c d i m s].include?(blvl)
        ftype_e_cdims_valid?(record)
      elsif %w[f].include?(type) && %w[c d m].include?(blvl)
        ftype_f_cdm_valid?(record)
      elsif %w[g].include?(type) && %w[c d m].include?(blvl)
        ftype_g_cdm_valid?(record)
      elsif %w[g].include?(type) && %w[i s].include?(blvl)
        ftype_g_is_valid?(record)
      elsif %w[i j].include?(type) && %w[c d m].include?(blvl)
        ftype_ij_cdm_valid?(record)
      elsif %w[i j].include?(type) && %w[i s].include?(blvl)
        ftype_ij_is_valid?(record)
      elsif %w[k].include?(type) && %w[c d m].include?(blvl)
        ftype_k_cdm_valid?(record)
      elsif %w[k].include?(type) && %w[i s].include?(blvl)
        ftype_k_is_valid?(record)
      elsif %w[m].include?(type) && %w[c d m].include?(blvl)
        ftype_m_cdm_valid?(record)
      elsif %w[m].include?(type) && %w[i s].include?(blvl)
        ftype_m_is_valid?(record)
      elsif %w[o r].include?(type) && %w[c d m].include?(blvl)
        ftype_or_cdm_valid?(record)
      elsif %w[o r].include?(type) && %w[i s].include?(blvl)
        ftype_or_is_valid?(record)
      elsif %w[p].include?(type) && %w[c d].include?(blvl)
        ftype_p_cd_valid?(record)
      else
        true
      end
    valid ? false : true
  end
end
