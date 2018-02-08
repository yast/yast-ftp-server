#! /usr/bin/env rspec

ENV["Y2DIR"] = File.expand_path("../../src", __FILE__)

require "yast"

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    # Don't measure coverage of the tests themselves.
    add_filter "/test/"
  end

  # track all ruby files under src
  src_location = File.expand_path("../../src", __FILE__)
  SimpleCov.track_files("#{src_location}/**/*.rb")

  # use coveralls for on-line code coverage reporting at Travis CI
  if ENV["TRAVIS"]
    require "coveralls"
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter
    ]
  end
end

# stub module to prevent its Import
# Useful for modules from different yast packages, to avoid build dependencies
def stub_module(name)
  Yast.const_set name.to_sym, Class.new { def self.fake_method; end }
end

stub_module("Users")

Yast.import "FtpServer"

VS_CONFIG_PATH = Yast::Path.new(".vsftpd")
PURE_CONFIG_PATH = Yast::Path.new(".pure-ftpd")

def mock_config(config_path, map)
  allow(Yast::SCR).to receive(:Dir).with(config_path).and_return(map.keys)
  map.each_pair do |key, value|
    allow(Yast::SCR).to receive(:Read).with(config_path + key).and_return(value)
  end
end

VS_SETTINGS = {
  "write_enable" => "NO",
  "dirmessage_enable" => "YES",
  "nopriv_user" => "ftpsecure",
  "local_enable" => "YES",
  "anonymous_enable" => "YES",
  "anon_world_readable_only" => "YES",
  "syslog_enable" => "YES",
  "connect_from_port_20" => "YES",
  "ascii_upload_enable" => "YES",
  "pam_service_name" => "vsftpd",
  "listen" => "NO",
  "listen_ipv6" => "YES",
  "ssl_enable" => "NO",
  "pasv_min_port" => "30000",
  "pasv_max_port" => "30100"
}

describe "Yast::FtpServer" do
  describe ".Modified" do
    it "returns false if no modification happens" do
      expect(Yast::FtpServer.Modified).to eq false
    end
  end

  describe ".ValueUI" do
    context "'VerboseLogging' when getting vsftpd settings" do
      it "returns default value 'YES' if 'log_ftp_protocol' missing in config file" do
        mock_config(VS_CONFIG_PATH, VS_SETTINGS)
        Yast::FtpServer.ReadVSFTPDSettings()

        expect(Yast::FtpServer.ValueUI("VerboseLogging", false)).to eql "YES"
      end

      it "returns value from config file 'NO' if 'log_ftp_protocol = NO' in config file" do
        mock_config(VS_CONFIG_PATH, VS_SETTINGS.merge("log_ftp_protocol" => "NO"))
        Yast::FtpServer.ReadVSFTPDSettings()

        expect(Yast::FtpServer.ValueUI("VerboseLogging", false)).to eql "NO"
      end

      it "returns value from config file 'YES' if 'log_ftp_protocol = YES' in config file" do
        mock_config(VS_CONFIG_PATH, VS_SETTINGS.merge("log_ftp_protocol" => "YES"))
        Yast::FtpServer.ReadVSFTPDSettings()

        expect(Yast::FtpServer.ValueUI("VerboseLogging", false)).to eql "YES"
      end
    end
  end
end
