module Marc_Cleanup
  module OracleConnection

    def connection
      conn = OCI8.new(USER, PASS, NAME)
      yield conn
    ensure
      conn.logoff unless conn.nil?
    end

  end
end
