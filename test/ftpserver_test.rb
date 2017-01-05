#! /usr/bin/env rspec

ENV["Y2DIR"] = File.expand_path("../../src", __FILE__)

require "yast"

# stub module to prevent its Import
# Useful for modules from different yast packages, to avoid build dependencies
def stub_module(name)
  Yast.const_set name.to_sym, Class.new { def self.fake_method; end }
end

stub_module("Users")
stub_module("Inetd")

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
  describe ".Modified" do
    it "returns false if no modification happens" do
      expect(Yast::FtpServer.Modified).to eq false
    end
  end

  describe ".GetPassivePortRangeBoundaries" do
    it "can read boundaries when separated by colon" do
      Yast::FtpServer.PURE_SETTINGS = { "PassivePortRange" => "1024:4201" }

      expected_boundaries = ["1024", "4201"]

      expect(Yast::FtpServer.GetPassivePortRangeBoundaries).to eq expected_boundaries
    end

    it "can read boundaries when separated by whitespace" do
      Yast::FtpServer.PURE_SETTINGS = { "PassivePortRange" => "1024 \t 4201" }

      expected_boundaries = ["1024", "4201"]

      expect(Yast::FtpServer.GetPassivePortRangeBoundaries).to eq expected_boundaries
    end

    it "returns nil if boundaries is spearated by invalid delimeter" do
      Yast::FtpServer.PURE_SETTINGS = { "PassivePortRange" => "1024::4201" }

      expect(Yast::FtpServer.GetPassivePortRangeBoundaries).to eq nil
    end
  end

  describe ".ValueUI" do
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

    context "using vsftpd" do
      before do
        Yast::FtpServer.vsftpd_edit = true
        # Init values to a known (and invalid) state
        mock_config(VS_CONFIG_PATH,
                    VS_SETTINGS.merge("listen" => "", "listen_ipv6" => ""))
      end

      context "configured to use xinetd" do
        before do
          Yast::FtpServer.EDIT_SETTINGS["StartDaemon"] = "2"
          Yast::FtpServer.EDIT_SETTINGS["StartXinetd"] = "YES"
        end

        it "disables vsftpd's standalone mode when writing StartXinetd" do
          allow(Yast::Service).to receive(:Enabled).and_return false

          Yast::FtpServer.ValueUI("StartXinetd", true)

          expect(Yast::FtpServer.VS_SETTINGS["listen"]).to eq("NO")
          expect(Yast::FtpServer.VS_SETTINGS["listen_ipv6"]).to eq("NO")
        end

        it "disables vsftpd service when writing StartXinetd" do
          allow(Yast::Service).to receive(:Enabled).with("pure-ftpd").and_return false
          allow(Yast::Service).to receive(:Enabled).with("vsftpd").and_return true
          expect(Yast::Service).to receive(:Disable).with("vsftpd")

          Yast::FtpServer.ValueUI("StartXinetd", true)
        end
      end

      context "configured to run at boot" do
        before do
          Yast::FtpServer.EDIT_SETTINGS["StartDaemon"] = "1"
        end

        it "enables vsftpd's standalone mode when writing StartXinetd" do
          allow(Yast::Service).to receive(:Disable)
          allow(Yast::Service).to receive(:Enable)

          Yast::FtpServer.ValueUI("StartXinetd", true)

          expect(Yast::FtpServer.VS_SETTINGS["listen"]).to eq("YES")
          expect(Yast::FtpServer.VS_SETTINGS["listen_ipv6"]).to be_nil
        end

        it "configures ftp services when writing StartXinetd" do
          expect(Yast::Service).to receive(:Disable).with("pure-ftpd")
          expect(Yast::Service).to receive(:Enable).with("vsftpd")

          Yast::FtpServer.ValueUI("StartXinetd", true)
        end
      end

      context "configured to run manually" do
        before do
          Yast::FtpServer.EDIT_SETTINGS["StartDaemon"] = "0"
        end

        it "enables vsftpd's standalone mode when writing StartXinetd" do
          allow(Yast::Service).to receive(:Disable)
          allow(Yast::Service).to receive(:Enable)

          Yast::FtpServer.ValueUI("StartXinetd", true)

          expect(Yast::FtpServer.VS_SETTINGS["listen"]).to eq("YES")
          expect(Yast::FtpServer.VS_SETTINGS["listen_ipv6"]).to be_nil
        end

        it "disables ftp services when writing StartXinetd" do
          expect(Yast::Service).to receive(:Disable).with("pure-ftpd")
          expect(Yast::Service).to receive(:Disable).with("vsftpd")

          Yast::FtpServer.ValueUI("StartXinetd", true)
        end
      end
    end
  end
end
