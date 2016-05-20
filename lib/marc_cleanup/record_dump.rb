require 'oci8'

module Marc_Cleanup

  def record_dump
    conn = OCI8.new(USER, PASS, NAME)
    cursor = conn.exec('SELECT TO_CHAR(MAX(BIB_ID)) AS MAX FROM BIB_DATA')
    row = cursor.fetch_hash
    cursor.close
    last_record = row['MAX'].to_i
    last_file_num = (last_record.to_f/500000).ceil
    file_num = 0

    loop do
      file_num += 1
      break if file_num > last_file_num
      File.open("./../marc/#{file_num}.mrc", 'a') do |output|
        conn.exec("SELECT RECORD_SEGMENT FROM BIB_DATA JOIN BIB_MASTER ON BIB_DATA.BIB_ID = BIB_MASTER.BIB_ID WHERE BIB_DATA.BIB_ID >= 1+((#{file_num}-1)*500000) AND BIB_DATA.BIB_ID <= 500000+((#{file_num}-1)*500000) AND BIB_MASTER.SUPPRESS_IN_OPAC = 'N'ORDER BY BIB_DATA.BIB_ID,SEQNUM") do |r|
          output.write(r.join(''))
        end
      end
    end
    conn.logoff
  end

  def changed_since_prompt
    conn = OCI8.new(USER, PASS, NAME)
    puts "What is the date cutoff (records after this date and time should be exported)? ('mm/dd/yyyy hh:mm:ss')"
    from_date = gets.chomp

    File.open("./../marctofix/changed_since.mrc", 'a') do |output|
      conn.exec("select record_segment from (bib_data join bib_master on bib_data.bib_id = bib_master.bib_id) join bib_history on bib_data.bib_id = bib_history.bib_id where action_date > to_date('#{from_date}', 'mm/dd/yyyy  hh:mi:ss') group by bib_data.bib_id, record_segment, seqnum order by bib_data.bib_id,seqnum") do |r|
        output.write(r.join(''))
      end
    end
    conn.logoff
  end 

end
