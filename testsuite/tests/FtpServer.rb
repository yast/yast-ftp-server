# encoding: utf-8

module Yast
  class FtpServerClient < Client
    def main
      # testedfiles: FtpServer.ycp

      Yast.include self, "testsuite.rb"
      TESTSUITE_INIT([], nil)

      Yast.import "FtpServer"

      DUMP("FtpServer::Modified")
      TEST(lambda { FtpServer.Modified }, [], nil)

      nil
    end
  end
end

Yast::FtpServerClient.new.main
