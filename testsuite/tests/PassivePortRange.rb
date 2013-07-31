# encoding: utf-8

module Yast
  class PassivePortRangeClient < Client
    def main
      Yast.import "Assert"
      Yast.import "FtpServer"

      # colon as delimiter
      FtpServer.PURE_SETTINGS = { "PassivePortRange" => "1024:4201" }

      @expected_boundaries = ["1024", "4201"]

      Assert.Equal(
        @expected_boundaries,
        FtpServer.GetPassivePortRangeBoundaries
      )

      # at least one whitespace as delimiter
      FtpServer.PURE_SETTINGS = { "PassivePortRange" => "1024 \t 4201" }

      Assert.Equal(
        @expected_boundaries,
        FtpServer.GetPassivePortRangeBoundaries
      )

      # invalid delimiter
      FtpServer.PURE_SETTINGS = { "PassivePortRange" => "1024::4201" }

      Assert.Equal(nil, FtpServer.GetPassivePortRangeBoundaries)

      nil
    end
  end
end

Yast::PassivePortRangeClient.new.main
