#! /usr/bin/env rspec

ENV["Y2DIR"] = File.expand_path("../../src", __FILE__)

require "yast"

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

PURE_SETTINGS = {
  "AllowAnonymousFXP"          => "no",
  "AllowDotFiles"              => "yes",
  "AllowUserFXP"               => "no",
  "AnonymousCanCreateDirs"     => "no",
  "AnonymousCantUpload"        => "yes",
  "AnonymousOnly"              => "yes",
  "AntiWarez"                  => "yes",
  "AutoRename"                 => "yes",
  "BrokenClientsCompatibility" => "no",
  "ChrootEveryone"             => "yes",
  "CustomerProof"              => "yes",
  "Daemonize"                  => "no",
  "DisplayDotFiles"            => "yes",
  "DontResolve"                => "yes",
  "LimitRecursion"             => "10000 8",
  "MaxClientsNumber"           => "10",
  "MaxClientsPerIP"            => "3",
  "MaxDiskUsage"               => "99",
  "MaxIdleTime"                => "15",
  "MaxLoad"                    => "4",
  "MinUID"                     => "40",
  "NoAnonymous"                => "no",
  "NoRename"                   => "yes",
  "PAMAuthentication"          => "yes",
  "PassivePortRange"           => "30000 30100",
  "ProhibitDotFilesRead"       => "no",
  "ProhibitDotFilesWrite"      => "yes",
  "SyslogFacility"             => "ftp",
  "VerboseLog"                 => "no"
}

describe "Yast::FtpServer" do
  describe "#ValueUI" do
    context "'VerboseLogging' when getting vsftpd settings" do
      before do
        Yast::FtpServer.vsftpd_edit = true
      end
      
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

    context "'VerboseLogging' when getting pure-ftpd settings" do
      before do
        Yast::FtpServer.vsftpd_edit = false
      end
      
      it "returns default value 'NO' if config file empty" do
        mock_config(PURE_CONFIG_PATH, {})
        Yast::FtpServer.ReadPUREFTPDSettings()
        
        expect(Yast::FtpServer.ValueUI("VerboseLogging", false)).to eql "NO"
      end

      it "returns value from config file 'NO' if 'VerboseLog = no' in config file" do
        mock_config(PURE_CONFIG_PATH, PURE_SETTINGS)
        Yast::FtpServer.ReadPUREFTPDSettings()
        
        expect(Yast::FtpServer.ValueUI("VerboseLogging", false)).to eql "NO"
      end
      
      it "returns value from config file 'YES' if 'VerboseLog = yes' in config file" do
        mock_config(PURE_CONFIG_PATH, PURE_SETTINGS.merge("VerboseLog" => "YES"))
        Yast::FtpServer.ReadPUREFTPDSettings()
        
        expect(Yast::FtpServer.ValueUI("VerboseLogging", false)).to eql "YES"
      end
    end

  end
end
