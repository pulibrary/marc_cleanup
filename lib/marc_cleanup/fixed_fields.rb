module MarcCleanup
  def no_001?(record)
    record['001'].nil?
  end

  def fixed_field_char_errors?(record)
    fields = record.fields('001'..'009').map(&:value)
    bad_fields = fields.reject { |value| value.bytesize == value.chars.size }
    bad_fields += fields.select { |value| value =~ /[^a-z0-9 \|.A-Z\-]/ }
    !bad_fields.empty?
  end

  def leader_char_errors?(record)
    record.leader =~ /[^0-9a-zA-Z ]/ ? true : false
  end

  def leader_errors?(record)
    correct_leader = /[0-9]{5}[acdnp][ac-gijkmoprt][a-dims][\sa][\sa]22[0-9]{5}[1-8uzI-M\s][aciu\s][abcr\s]4500/
    record.leader =~ correct_leader ? false : true
  end

  def bib_form(record)
    %w[a c d i j m p t].include?(record.leader[6]) ? record['008'].value[23] : record['008'].value[29]
  end

  def multiple_no_008?(record)
    record.fields('008').size != 1
  end

  def place_codes
    [
      'aa ',
      'abc',
      'ac ',
      'aca',
      'ae ',
      'af ',
      'ag ',
      'ai ',
      'ai ',
      'air',
      'aj ',
      'ajr',
      'aku',
      'alu',
      'am ',
      'an ',
      'ao ',
      'aq ',
      'aru',
      'as ',
      'at ',
      'au ',
      'aw ',
      'ay ',
      'azu',
      'ba ',
      'bb ',
      'bcc',
      'bd ',
      'be ',
      'bf ',
      'bg ',
      'bh ',
      'bi ',
      'bl ',
      'bm ',
      'bn ',
      'bo ',
      'bp ',
      'br ',
      'bs ',
      'bt ',
      'bu ',
      'bv ',
      'bw ',
      'bwr',
      'bx ',
      'ca ',
      'cau',
      'cb ',
      'cc ',
      'cd ',
      'ce ',
      'cf ',
      'cg ',
      'ch ',
      'ci ',
      'cj ',
      'ck ',
      'cl ',
      'cm ',
      'cn ',
      'co ',
      'cou',
      'cp ',
      'cq ',
      'cr ',
      'cs ',
      'ctu',
      'cu ',
      'cv ',
      'cw ',
      'cx ',
      'cy ',
      'cz ',
      'dcu',
      'deu',
      'dk ',
      'dm ',
      'dq ',
      'dr ',
      'ea ',
      'ec ',
      'eg ',
      'em ',
      'enk',
      'er ',
      'err',
      'es ',
      'et ',
      'fa ',
      'fg ',
      'fi ',
      'fj ',
      'fk ',
      'flu',
      'fm ',
      'fp ',
      'fr ',
      'fs ',
      'ft ',
      'gau',
      'gb ',
      'gd ',
      'ge ',
      'gg ',
      'gh ',
      'gi ',
      'gl ',
      'gm ',
      'gn ',
      'go ',
      'gp ',
      'gr ',
      'gs ',
      'gsr',
      'gt ',
      'gu ',
      'gv ',
      'gw ',
      'gy ',
      'gz ',
      'hiu',
      'hk ',
      'hm ',
      'ho ',
      'ht ',
      'hu ',
      'iau',
      'ic ',
      'idu',
      'ie ',
      'ii ',
      'ilu',
      'im ',
      'inu',
      'io ',
      'iq ',
      'ir ',
      'is ',
      'it ',
      'iu ',
      'iv ',
      'iw ',
      'iy ',
      'ja ',
      'je ',
      'ji ',
      'jm ',
      'jn ',
      'jo ',
      'ke ',
      'kg ',
      'kgr',
      'kn ',
      'ko ',
      'ksu',
      'ku ',
      'kv ',
      'kyu',
      'kz ',
      'kzr',
      'lau',
      'lb ',
      'le ',
      'lh ',
      'li ',
      'lir',
      'ln ',
      'lo ',
      'ls ',
      'lu ',
      'lv ',
      'lvr',
      'ly ',
      'mau',
      'mbc',
      'mc ',
      'mdu',
      'meu',
      'mf ',
      'mg ',
      'mh ',
      'miu',
      'mj ',
      'mk ',
      'ml ',
      'mm ',
      'mnu',
      'mo ',
      'mou',
      'mp ',
      'mq ',
      'mr ',
      'msu',
      'mtu',
      'mu ',
      'mv ',
      'mvr',
      'mw ',
      'mx ',
      'my ',
      'mz ',
      'na ',
      'nbu',
      'ncu',
      'ndu',
      'ne ',
      'nfc',
      'ng ',
      'nhu',
      'nik',
      'nju',
      'nkc',
      'nl ',
      'nm ',
      'nmu',
      'nn ',
      'no ',
      'np ',
      'nq ',
      'nr ',
      'nsc',
      'ntc',
      'nu ',
      'nuc',
      'nvu',
      'nw ',
      'nx ',
      'nyu',
      'nz ',
      'ohu',
      'oku',
      'onc',
      'oru',
      'ot ',
      'pau',
      'pc ',
      'pe ',
      'pf ',
      'pg ',
      'ph ',
      'pic',
      'pk ',
      'pl ',
      'pn ',
      'po ',
      'pp ',
      'pr ',
      'pt ',
      'pw ',
      'py ',
      'qa ',
      'qea',
      'quc',
      'rb ',
      're ',
      'rh ',
      'riu',
      'rm ',
      'ru ',
      'rur',
      'rw ',
      'ry ',
      'sa ',
      'sb ',
      'sc ',
      'scu',
      'sd ',
      'sdu',
      'se ',
      'sf ',
      'sg ',
      'sh ',
      'si ',
      'sj ',
      'sk ',
      'sl ',
      'sm ',
      'sn ',
      'snc',
      'so ',
      'sp ',
      'sq ',
      'sr ',
      'ss ',
      'st ',
      'stk',
      'su ',
      'sv ',
      'sw ',
      'sx ',
      'sy ',
      'sz ',
      'ta ',
      'tar',
      'tc ',
      'tg ',
      'th ',
      'ti ',
      'tk ',
      'tkr',
      'tl ',
      'tma',
      'tnu',
      'to ',
      'tr ',
      'ts ',
      'tt ',
      'tu ',
      'tv ',
      'txu',
      'tz ',
      'ua ',
      'uc ',
      'ug ',
      'ui ',
      'uik',
      'uk ',
      'un ',
      'unr',
      'up ',
      'ur ',
      'us ',
      'utu',
      'uv ',
      'uy ',
      'uz ',
      'uzr',
      'vau',
      'vb ',
      'vc ',
      've ',
      'vi ',
      'vm ',
      'vn ',
      'vp ',
      'vra',
      'vs ',
      'vtu',
      'wau',
      'wb ',
      'wea',
      'wf ',
      'wiu',
      'wj ',
      'wk ',
      'wlk',
      'ws ',
      'wvu',
      'wyu',
      'xa ',
      'xb ',
      'xc ',
      'xd ',
      'xe ',
      'xf ',
      'xga',
      'xh ',
      'xi ',
      'xj ',
      'xk ',
      'xl ',
      'xm ',
      'xn ',
      'xna',
      'xo ',
      'xoa',
      'xp ',
      'xr ',
      'xra',
      'xs ',
      'xv ',
      'xx ',
      'xxc',
      'xxk',
      'xxr',
      'xxu',
      'ye ',
      'ykc',
      'ys ',
      'yu ',
      'za '
    ]
  end

  def lang_codes
    %w[
      aar
      abk
      ace
      ach
      ada
      ady
      afa
      afh
      afr
      ain
      ajm
      aka
      akk
      alb
      ale
      alg
      alt
      amh
      ang
      anp
      apa
      ara
      arc
      arg
      arm
      arn
      arp
      art
      arw
      asm
      ast
      ath
      aus
      ava
      ave
      awa
      aym
      aze
      bad
      bai
      bak
      bal
      bam
      ban
      baq
      bas
      bat
      bej
      bel
      bem
      ben
      ber
      bho
      bih
      bik
      bin
      bis
      bla
      bnt
      bos
      bra
      bre
      btk
      bua
      bug
      bul
      bur
      byn
      cad
      cai
      cam
      car
      cat
      cau
      ceb
      cel
      cha
      chb
      che
      chg
      chi
      chk
      chm
      chn
      cho
      chp
      chr
      chu
      chv
      chy
      cmc
      cnr
      cop
      cor
      cos
      cpe
      cpf
      cpp
      cre
      crh
      crp
      csb
      cus
      cze
      dak
      dan
      dar
      day
      del
      den
      dgr
      din
      div
      doi
      dra
      dsb
      dua
      dum
      dut
      dyu
      dzo
      efi
      egy
      eka
      elx
      eng
      enm
      epo
      esk
      esp
      est
      eth
      ewe
      ewo
      fan
      fao
      far
      fat
      fij
      fil
      fin
      fiu
      fon
      fre
      fri
      frm
      fro
      frr
      frs
      fry
      ful
      fur
      gaa
      gae
      gag
      gal
      gay
      gba
      gem
      geo
      ger
      gez
      gil
      gla
      gle
      glg
      glv
      gmh
      goh
      gon
      gor
      got
      grb
      grc
      gre
      grn
      gsw
      gua
      guj
      gwi
      hai
      hat
      hau
      haw
      heb
      her
      hil
      him
      hin
      hit
      hmn
      hmo
      hrv
      hsb
      hun
      hup
      iba
      ibo
      ice
      ido
      iii
      ijo
      iku
      ile
      ilo
      ina
      inc
      ind
      ine
      inh
      int
      ipk
      ira
      iri
      iro
      ita
      jav
      jbo
      jpn
      jpr
      jrb
      kaa
      kab
      kac
      kal
      kam
      kan
      kar
      kas
      kau
      kaw
      kaz
      kbd
      kha
      khi
      khm
      kho
      kik
      kin
      kir
      kmb
      kok
      kom
      kon
      kor
      kos
      kpe
      krc
      krl
      kro
      kru
      kua
      kum
      kur
      kus
      kut
      lad
      lah
      lam
      lan
      lao
      lap
      lat
      lav
      lez
      lim
      lin
      lit
      lol
      loz
      ltz
      lua
      lub
      lug
      lui
      lun
      luo
      lus
      mac
      mad
      mag
      mah
      mai
      mak
      mal
      man
      mao
      map
      mar
      mas
      max
      may
      mdf
      mdr
      men
      mga
      mic
      min
      mis
      mkh
      mla
      mlg
      mlt
      mnc
      mni
      mno
      moh
      mol
      mon
      mos
      mul
      mun
      mus
      mwl
      mwr
      myn
      myv
      nah
      nai
      nap
      nau
      nav
      nbl
      nde
      ndo
      nds
      nep
      new
      nia
      nic
      niu
      nno
      nob
      nog
      non
      nor
      nqo
      nso
      nub
      nwc
      nya
      nym
      nyn
      nyo
      nzi
      oci
      oji
      ori
      orm
      osa
      oss
      ota
      oto
      paa
      pag
      pal
      pam
      pan
      pap
      pau
      peo
      per
      phi
      phn
      pli
      pol
      pon
      por
      pra
      pro
      pus
      que
      raj
      rap
      rar
      roa
      roh
      rom
      rum
      run
      rup
      rus
      sad
      sag
      sah
      sai
      sal
      sam
      san
      sao
      sas
      sat
      scc
      scn
      sco
      scr
      sel
      sem
      sga
      sgn
      shn
      sho
      sid
      sin
      sio
      sit
      sla
      slo
      slv
      sma
      sme
      smi
      smj
      smn
      smo
      sms
      sna
      snd
      snh
      snk
      sog
      som
      son
      sot
      spa
      srd
      srn
      srp
      srr
      ssa
      sso
      ssw
      suk
      sun
      sus
      sux
      swa
      swe
      swz
      syc
      syr
      tag
      tah
      tai
      taj
      tam
      tar
      tat
      tel
      tem
      ter
      tet
      tgk
      tgl
      tha
      tib
      tig
      tir
      tiv
      tkl
      tlh
      tli
      tmh
      tog
      ton
      tpi
      tru
      tsi
      tsn
      tso
      tsw
      tuk
      tum
      tup
      tur
      tut
      tvl
      twi
      tyv
      udm
      uga
      uig
      ukr
      umb
      und
      urd
      uzb
      vai
      ven
      vie
      vol
      vot
      wak
      wal
      war
      was
      wel
      wen
      wln
      wol
      xal
      xho
      yao
      yap
      yid
      yor
      ypk
      zap
      zbl
      zen
      zha
      znd
      zul
      zun
      zxx
      zza
    ]
  end

  def illus_codes
    /^[ a-mop]+$/
  end

  def audience_codes
    /[ a-gj|]/
  end

  def item_form_codes
    /[ a-dfoq-s|]/
  end

  def item_orig_form_codes
    /[ a-foqs|]/
  end

  def contents_codes
    /^[ a-gi-wyz256]+$/
  end

  def gov_pub_codes
    /[ acfilmosuz|]/
  end

  def lit_form_codes
    /[01c-fhijmpsu|]/
  end

  def biog_codes
    /[ abcd|]/
  end

  def comp_type_codes
    /[a-jmuz|]/
  end

  def relief_codes
    /^[ a-gi-kmz]+$/
  end

  def proj_codes
    [
      '  ',
      'aa',
      'ab',
      'ac',
      'ad',
      'ae',
      'af',
      'ag',
      'am',
      'an',
      'ap',
      'au',
      'az',
      'ba',
      'bb',
      'bc',
      'bd',
      'be',
      'bf',
      'bg',
      'bh',
      'bi',
      'bj',
      'bk',
      'bl',
      'bo',
      'br',
      'bs',
      'bu',
      'bz',
      'ca',
      'cb',
      'cc',
      'ce',
      'cp',
      'cu',
      'cz',
      'da',
      'db',
      'dc',
      'dd',
      'de',
      'df',
      'dg',
      'dh',
      'dl',
      'zz',
      '||'
    ]
  end

  def map_type_codes
    /[a-guz|]/
  end

  def map_special_format_codes
    /[ ejklnoprz]+/
  end

  def comp_codes_uris
    {
      'an' => 'gf2014026635',
      'bd' => 'gf2014026648',
      'bg' => 'gf2014026664',
      'bl' => 'gf2014026665',
      'bt' => 'gf2014026650',
      'ca' => 'gf2014026701',
      'cb' => 'gf2014026707',
      'cc' => 'gf2014026707',
      'cg' => 'gf2014026724',
      'ch' => 'gf2014026713',
      'cl' => 'gf2014026712',
      'cn' => 'gf2014026687',
      'co' => 'gf2014026725',
      'cp' => 'gf2014027007',
      'cr' => 'gf2014026695',
      'cs' => 'gf2014026624',
      'ct' => 'gf2014026688',
      'cy' => 'gf2014026739',
      'dv' => 'gf2014027116',
      'fg' => 'gf2014026818',
      'fl' => 'gf2014026806',
      'fm' => 'gf2014026809',
      'ft' => 'gf2018026018',
      'gm' => 'gf2014026839',
      'hy' => 'gf2014026872',
      'jz' => 'gf2014026879',
      'mc' => 'gf2014027050',
      'md' => 'gf2014026915',
      'mi' => 'gf2014026940',
      'mo' => 'gf2014026949',
      'mp' => 'gf2014026950',
      'mr' => 'gf2014026922',
      'ms' => 'gf2014026926',
      'mz' => 'gf2014026928',
      'nc' => 'gf2017026144',
      'op' => 'gf2014026976',
      'or' => 'gf2014026977',
      'ov' => 'gf2014026980',
      'pg' => 'gf2014027017',
      'pm' => 'gf2014026861',
      'po' => 'gf2014027005',
      'pp' => 'gf2014027009',
      'pr' => 'gf2014027013',
      'ps' => 'gf2014026989',
      'pt' => 'gf2014026984',
      'pv' => 'gf2014026994',
      'rc' => 'gf2014027054',
      'rd' => 'gf2014027057',
      'rg' => 'gf2014027034',
      'ri' => 'gf2017026128',
      'rp' => 'gf2014027051',
      'rq' => 'gf2014027048',
      'sd' => 'gf2014027111',
      'sg' => 'gf2014027103',
      'sn' => 'gf2014027099',
      'sp' => 'gf2014027120',
      'st' => 'gf2014027115',
      'su' => 'gf2014027116',
      'sy' => 'gf2014027121',
      'tc' => 'gf2014027140',
      'vi' => 'gf2017026025',
      'vr' => 'gf2014027156',
      'wz' => 'gf2014027167',
      'za' => 'gf2016026059'
    }
  end

  def composition_codes
    %w[
      an
      bd
      bg
      bl
      bt
      ca
      cb
      cc
      cg
      ch
      cl
      cn
      co
      cp
      cr
      cs
      ct
      cy
      cz
      df
      dv
      fg
      fl
      fm
      ft
      gm
      hy
      jz
      mc
      md
      mi
      mo
      mp
      mr
      ms
      mu
      mz
      nc
      nn
      op
      or
      ov
      pg
      pm
      po
      pp
      pr
      ps
      pt
      pv
      rc
      rd
      rg
      ri
      rp
      rq
      sd
      sg
      sn
      sp
      st
      su
      sy
      tc
      tl
      ts
      uu
      vi
      vr
      wz
      za
      zz
      ||
    ]
  end

  def music_format_codes
    /[a-eg-npuz|]/
  end

  def music_part_codes
    /[ defnu|]/
  end

  def accompany_codes
    /^[ a-ikrsz]+$/
  end

  def lit_text_codes
    /^[ a-prstz]+$/
  end

  def transpose_codes
    /[ abcnu|]/
  end

  def freq_codes
    /[ a-kmqstuwz|]/
  end

  def cr_type_codes
    /[ dlmnpw|]/
  end

  def cr_contents_codes
    /^[ a-ik-wyz56]+/
  end

  def orig_script_codes
    /[ a-luz|]/
  end

  def visual_type_codes
    /^[a-dfgik-tvwz|]$/
  end

  def all_008(field)
    date_entered = field[0..5]
    date_type = field[6]
    date1 = field[7..10]
    date2 = field[11..14]
    place = field[15..17]
    lang = field[35..37]
    modified = field[38]
    cat_source = field[39]
    return true unless date_entered =~ /^[0-9]{6}$/
    return true unless %w[b c d e i k m n p q r s t u |].include?(date_type)
    return true unless date1 == '||||' || date1 == '    ' || date1 =~ /^[0-9u]{4}$/
    case date_type
    when 'e'
      return true unless date2 =~ /^[0-9]+[ ]*$/
    else
      return true unless date2 == '||||' || date2 == '    ' || date2 =~ /^[0-9u]{4}$/
    end
    return true unless place == '|||' || place_codes.include?(place)
    return true unless lang == '|||'  || lang_codes.include?(lang)
    return true unless %w[\  d o r s x |].include?(modified)
    return true unless %w[\  c d u |].include?(cat_source)
    false
  end

  def book_008(field)
    illus = field[0..3]
    audience = field[4]
    item_form = field[5]
    contents = field[6..9]
    gov_pub = field[10]
    conf_pub = field[11]
    festschrift = field[12]
    index = field[13]
    undefined = field[14]
    lit_form = field[15]
    biog = field[16]
    return true unless illus == '||||' || illus =~ illus_codes
    return true unless audience =~ audience_codes
    return true unless item_form =~ item_form_codes
    return true unless contents == '||||' || contents =~ contents_codes
    return true unless gov_pub =~ gov_pub_codes
    return true unless %w[0 1 |].include?(conf_pub)
    return true unless %w[0 1 |].include?(festschrift)
    return true unless %w[0 1 |].include?(index)
    return true unless undefined == ' '
    return true unless lit_form =~ lit_form_codes
    return true unless biog =~ biog_codes
    false
  end

  def comp_008(field)
    undef1 = field[0..3]
    audience = field[4]
    item_form = field[5]
    undef2 = field[6..7]
    type = field[8]
    undef3 = field[9]
    gov_pub = field[10]
    undef4 = field[11..16]
    return true unless ['||||', '    '].include?(undef1)
    return true unless audience =~ audience_codes
    return true unless item_form =~ /[ oq|]/
    return true unless ['  ', '||'].include?(undef2)
    return true unless type =~ comp_type_codes
    return true unless %w[\  |].include?(undef3)
    return true unless gov_pub =~ gov_pub_codes
    return true unless ['||||||', '      '].include?(undef4)
    false
  end

  def map_008(field)
    relief = field[0..3]
    proj = field[4..5]
    undef1 = field[6]
    type = field[7]
    undef2 = field[8..9]
    gov_pub = field[10]
    item_form = field[11]
    undef3 = field[12]
    index = field[13]
    undef4 = field[14]
    format = field[15..16]
    return true unless relief == '||||' || relief =~ relief_codes
    return true unless proj_codes.include?(proj)
    return true unless [' ', '|'].include?(undef1)
    return true unless type =~ map_type_codes
    return true unless ['||', '  '].include?(undef2)
    return true unless gov_pub =~ gov_pub_codes
    return true unless item_form =~ item_form_codes
    return true unless [' ', '|'].include?(undef3)
    return true unless %w[0 1 |].include?(index)
    return true unless [' ', '|'].include?(undef4)
    return true unless format == '||' || format =~ map_special_format_codes
    false
  end

  def music_008(field)
    comp_form = field[0..1]
    music_format = field[2]
    parts = field[3]
    audience = field[4]
    item_form = field[5]
    accompanying = field[6..11]
    lit_text = field[12..13]
    undef1 = field[14]
    transpose = field[15]
    undef2 = field[16]
    return true unless composition_codes.include?(comp_form)
    return true unless music_format =~ music_format_codes
    return true unless parts =~ music_part_codes
    return true unless audience =~ audience_codes
    return true unless item_form =~ item_form_codes
    return true unless accompanying == '||||||' || accompanying =~ accompany_codes
    return true unless lit_text == '||' || lit_text =~ lit_text_codes
    return true unless [' ', '|'].include?(undef1)
    return true unless transpose =~ transpose_codes
    return true unless [' ', '|'].include?(undef2)
    false
  end

  def continuing_resource_008(field)
    freq = field[0]
    reg = field[1]
    undef1 = field[2]
    cr_type = field[3]
    item_orig_form = field[4]
    item_form = field[5]
    work_nature = field[6]
    contents = field[7..9]
    gov_pub = field[10]
    conf_pub = field[11]
    undef2 = field[12..14]
    orig_script = field[15]
    entry = field[16]
    return true unless freq =~ freq_codes
    return true unless %w[n r u x |].include?(reg)
    return true unless [' ', '|'].include?(undef1)
    return true unless cr_type =~ cr_type_codes
    return true unless item_orig_form =~ item_orig_form_codes
    return true unless item_form =~ item_form_codes
    return true unless work_nature == '|' || work_nature =~ cr_contents_codes
    return true unless contents == '|||' || contents =~ cr_contents_codes
    return true unless gov_pub =~ gov_pub_codes
    return true unless ['0', '1', '|'].include?(conf_pub)
    return true unless ['   ', '|||'].include?(undef2)
    return true unless orig_script =~ orig_script_codes
    return true unless %w[0 1 2 |].include?(entry)
    false
  end

  def visual_008(field)
    runtime = field[0..2]
    undef1 = field[3]
    audience = field[4]
    undef2 = field[5..9]
    gov_pub = field[10]
    item_form = field[11]
    undef3 = field[12..14]
    visual_type = field[15]
    technique = field[16]
    return true unless %w[nnn --- |||].include?(runtime) || runtime =~ /^[0-9]{3}$/
    return true unless [' ', '|'].include?(undef1)
    return true unless audience =~ audience_codes
    return true unless ['     ', '|||||'].include?(undef2)
    return true unless gov_pub =~ gov_pub_codes
    return true unless item_form =~ item_form_codes
    return true unless ['   ', '|||'].include?(undef3)
    return true unless visual_type =~ visual_type_codes
    return true unless %w[a c l n u z |].include?(technique)
  end

  def mix_mat_008(field)
    undef1 = field[0..4]
    item_form = field[5]
    undef2 = field[6..16]
    return true unless ['     ', '|||||'].include?(undef1)
    return true unless item_form =~ item_form_codes
    return true unless ['           ', '|||||||||||'].include?(undef2)
    false
  end

  def book
    %w[
      aa
      ac
      ad
      am
      ta
      tc
      td
      tm
    ]
  end

  def comp_file
    %w[
      ma
      mb
      mc
      md
      mi
      mm
      ms
    ]
  end

  def map
    %w[
      ea
      eb
      ec
      ed
      ei
      em
      es
      fa
      fb
      fc
      fd
      fi
      fm
      fs
    ]
  end

  def music
    %w[
      ca
      cb
      cc
      cd
      ci
      cm
      cs
      da
      db
      dc
      dd
      di
      dm
      ds
      ia
      ib
      ic
      id
      ii
      im
      is
      ja
      jb
      jc
      jd
      ji
      jm
      js
    ]
  end

  def continuing_resource
    %w[
      ab
      ai
      as
      tb
      ti
      ts
    ]
  end

  def visual
    %w[
      ga
      gb
      gc
      gd
      gi
      gm
      gs
      ka
      kb
      kc
      kd
      ki
      km
      ks
      oa
      ob
      oc
      od
      oi
      om
      os
      ra
      rb
      rc
      rd
      ri
      rm
      rs
    ]
  end

  def mixed
    %w[
      pa
      pb
      pc
      pd
      pi
      pm
      ps
    ]
  end

  def bad_005?(record)
    field = record['005']
    return false unless field
    field.value =~ /^[0-9]{14}\.[0-9]$/ ? false : true
  end

  # Uses same methods as the specific 008 methods
  def bad_006?(record)
    fields = record.fields('006')
    return false if fields.empty?
    fields.each do |field|
      return true if field.value.length != 18
      rec_type = field.value[0]
      specific_006 = field.value[1..-1]
      case rec_type
      when 'a', 't'
        return true if book_008(specific_006)
      when 'm'
        return true if comp_008(specific_006)
      when 'w', 'f'
        return true if map_008(specific_006)
      when 'c', 'd', 'i', 'j'
        return true if music_008(specific_006)
      when 's'
        return true if continuing_resource_008(specific_006)
      when 'w', 'g', 'k', 'o', 'r'
        return true if visual_008(specific_006)
      when 'p'
        return true if mix_mat_008(specific_006)
      end
    end
    false
  end

  def map_007(field)
    return true unless field.length == 7
    return true unless %w[d g j k q r s u y z |].include?(field[0])
    return true unless field[1] == ' '
    return true unless %w[a c |].include?(field[2])
    return true unless %w[a b c d e f g i j l n p q r s t u v w x y z |].include?(field[3])
    return true unless %w[f n u z |].include?(field[4])
    return true unless %w[a b c d u z |].include?(field[5])
    return true unless %w[a b m n |].include?(field[6])
    false
  end

  def elec_007(field)
    return true unless field.length == 13
    return true unless %w[a b c d e f h j k m o r s u z |].include?(field[0])
    return true unless field[1] == ' '
    return true unless %w[a b c g m n u z |].include?(field[2])
    return true unless %w[a e g i j n o u v z |].include?(field[3])
    return true unless %w[\  a u |].include?(field[4])
    return true unless %w[mmm nnn --- |||].include?(field[5..7]) || field[5..7] =~ /^[0-9]{3}$/
    return true unless %w[a m u |].include?(field[8])
    return true unless %w[a n p u |].include?(field[9])
    return true unless %w[a b c d m n u |].include?(field[10])
    return true unless %w[a b d m u |].include?(field[11])
    return true unless %w[a n p r u |].include?(field[12])
    false
  end

  def globe_007(field)
    return true unless field.length == 5
    return true unless %w[a b c e u z |].include?(field[0])
    return true unless field[1] == ' '
    return true unless %w[a c |].include?(field[2])
    return true unless %w[a b c d e f g i l n p u v w z |].include?(field[3])
    return true unless %w[f n u z |].include?(field[4])
    false
  end

  def tactile_007(field)
    return true unless field.length == 9
    return true unless %w[a b c d u z |].include?(field[0])
    return true unless field[1] == ' '
    return true unless field[2..3] == '||' || field[2..3] =~ /^[abcdemnuz ]{2}$/
    return true unless %w[a b m n u z |].include?(field[4])
    return true unless field[5..7] == '||' || field[5..7] =~ /^[abcdefghijklnuz ]{3}$/
    return true unless %w[a b n u z |].include?(field[8])
    false
  end

  def proj_graphic_007(field)
    return true unless field.length == 8
    return true unless %w[c d f o s t u z |].include?(field[0])
    return true unless field[1] == ' '
    return true unless %w[a b c h m n u z |].include?(field[2])
    return true unless %w[d e j k m o u z |].include?(field[3])
    return true unless %w[\  a b u |].include?(field[4])
    return true unless %w[\  a b c d e f g h i u z |].include?(field[5])
    return true unless %w[a b c d e f g j k s t v w x y u z |].include?(field[6])
    return true unless %w[\  c d e h j k m u z |].include?(field[7])
    false
  end

  def microform_007(field)
    return true unless field.length == 12
    return true unless %w[a b c d e f g h j u z |].include?(field[0])
    return true unless field[1] == ' '
    return true unless %w[a b m u |].include?(field[2])
    return true unless %w[a d f g h l m o p u z |].include?(field[3])
    return true unless %w[a b c d e u v |].include?(field[4])
    return true unless field[5..7] == '|||' || field[5..7] =~ /^[0-9]+[\-]*$/
    return true unless %w[a m u |].include?(field[8])
    return true unless %w[a n p u |].include?(field[9])
    return true unless %w[a b c d m n u |].include?(field[10])
    return true unless %w[a b d m u |].include?(field[11])
    return true unless %w[a n p r u |].include?(field[12])
    false
  end

  def nonproj_graphic_007(field)
    return true unless field.length == 5
    return true unless %w[a c d e f g h i j k l n o p q r s u v z |].include?(field[0])
    return true unless field[1] == ' '
    return true unless %w[a b c h m u z |].include?(field[2])
    return true unless %w[a b c d e f g h i l m n o p q r s t u v w z |].include?(field[3])
    return true unless %w[\  a b c d e f g h i l m n o p q r s t u v w z |].include?(field[4])
    false
  end

  def motion_pict_007(field)
    return true unless field.length > 6
    return true unless %w[c f o r u z |].include?(field[0])
    return true unless field[1] == ' '
    return true unless %w[b c h m n u z |].include?(field[2])
    return true unless %w[a b c d e f u z |].include?(field[3])
    return true unless %w[\  a b u |].include?(field[4])
    return true unless %w[\  a b c d e f g h i u z |].include?(field[5])
    return true unless %w[a b c d e f g u z |].include?(field[6])
    return true unless field[7].nil? || field[7] =~ /[kmnqsuz|]/
    return true unless field[8].nil? || field[8] =~ /[a-gnz|]/
    return true unless field[9].nil? || field[9] =~ /[abnuz|]/
    return true unless field[10].nil? || field[10] =~ /[deoruz|]/
    return true unless field[11].nil? || field[11] =~ /[acdimnprtuz|]/
    return true unless field[12].nil? || field[12] =~ /[a-np-vz|]/
    return true unless field[13].nil? || field[13] =~ /[abcdnuz|]/
    return true unless field[14].nil? || field[14] =~ /[a-hklm|]/
    return true unless field[15].nil? || field[15] =~ /[cinu|]/
    inspect_date = field[16..21]
    case inspect_date
    when '||||||', '------'
      false
    when /^[0-9]+[\-]*$/
      false
    else
      true
    end
  end

  def kit_mus_007(field)
    return true unless field.length == 1
    %w[u |].include?(field[0]) ? false : true
  end

  def remote_data_types
    %w[
      aa
      da
      db
      dc
      dd
      de
      df
      dv
      dz
      ga
      gb
      gc
      gd
      ge
      gf
      gg
      gu
      gz
      ja
      jb
      jc
      jv
      jz
      ma
      mb
      mm
      nn
      pa
      pb
      pc
      pd
      pe
      pz
      ra
      rb
      rc
      rd
      sa
      ta
      uu
      zz
      ||
    ]
  end

  def remote_007(field)
    return true unless field.length == 10
    return true unless field[0] =~ /[u|]/
    return true unless field[1] == ' '
    return true unless field[2] =~ /[abcnuz|]/
    return true unless field[3] =~ /[abcnu|]/
    return true unless field[4] =~ /[0-9nu|]/
    return true unless field[5] =~ /[a-inuz|]/
    return true unless field[6] =~ /[abcmnuz|]/
    return true unless field[7] =~ /[abuz|]/
    return true unless remote_data_types.include? field[8..9]
    false
  end

  def recording_007(field)
    return true unless field.length == 13
    return true unless %w[d e g i q r s t u w z |].include?(field[0])
    return true unless field[1] == ' '
    return true unless field[2] =~ /[a-fhik-pruz|]/
    return true unless field[3] =~ /[mqsuz|]/
    return true unless field[4] =~ /[mnsuz|]/
    return true unless field[5] =~ /[a-gjnosuz|]/
    return true unless field[6] =~ /[l-puz|]/
    return true unless field[7] =~ /[a-fnuz|]/
    return true unless field[8] =~ /[abdimnrstuz|]/
    return true unless field[9] =~ /[abcgilmnprswuz|]/
    return true unless field[10] =~ /[hlnu|]/
    return true unless field[11] =~ /[a-hnuz|]/
    return true unless field[12] =~ /[abdeuz|]/
    false
  end

  def text_007(field)
    return true unless field.length == 1
    %w[a b c d u z |].include?(field[0]) ? false : true
  end

  def video_007(field)
    return true unless field.length == 8
    return true unless %w[c d f r u z |].include?(field[0])
    return true unless field[1] == ' '
    return true unless %w[a b c m n u z |].include?(field[2])
    return true unless field[3] =~ /[a-kmopqsuvz|]/
    return true unless %w[\  a b u |].include?(field[4])
    return true unless %w[\  a b c d e f g h i u z |].include?(field[5])
    return true unless %w[a m o p q r u z |].include?(field[6])
    return true unless %w[k m n q s u z |].include?(field[7])
    false
  end

  def unspec_007(field)
    return true unless field.length == 1
    %w[m u z |].include?(field[0]) ? false : true
  end

  def bad_007?(record)
    fields = record.fields('007')
    return false if fields.empty?
    fields.each do |field|
      rec_type = field.value[0]
      specific_f007 = field.value[1..-1]
      return true unless specific_f007
      case rec_type
      when 'a'
        return true if map_007(specific_f007)
      when 'c'
        return true if elec_007(specific_f007)
      when 'd'
        return true if globe_007(specific_f007)
      when 'f'
        return true if tactile_007(specific_f007)
      when 'g'
        return true if proj_graphic_007(specific_f007)
      when 'h'
        return true if microform_007(specific_f007)
      when 'k'
        return true if nonproj_graphic_007(specific_f007)
      when 'm'
        return true if motion_pict_007(specific_f007)
      when 'o' || 'q'
        return true if kit_mus_007(specific_f007)
      when 'r'
        return true if remote_007(specific_f007)
      when 's'
        return true if recording_007(specific_f007)
      when 't'
        return true if text_007(specific_f007)
      when 'v'
        return true if video_007(specific_f007)
      when 'z'
        return true if unspec_007(specific_f007)
      else
        return true
      end
    end
    false
  end

  def bad_008_length?(record)
    field = record['008'].value
    field.length != 40
  end

  def bad_008?(record)
    field = record['008'].value
    return true if field.length != 40
    return true if all_008(field)
    rec_type = record.leader[6..7]
    specific_f008 = field[18..34]
    if book.include?(rec_type)
      return true if book_008(specific_f008)
    elsif comp_file.include?(rec_type)
      return true if comp_008(specific_f008)
    elsif map.include?(rec_type)
      return true if map_008(specific_f008)
    elsif music.include?(rec_type)
      return true if music_008(specific_f008)
    elsif continuing_resource.include?(rec_type)
      return true if continuing_resource_008(specific_f008)
    elsif visual.include?(rec_type)
      return true if visual_008(specific_f008)
    elsif mixed.include?(rec_type)
      return true if mix_mat_008(specific_f008)
    end
    false
  end
end
