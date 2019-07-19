#! /usr/bin/env rspec

# Copyright (c) [2019] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require_relative "../spec_helper.rb"

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
  "write_enable"             => "NO",
  "dirmessage_enable"        => "YES",
  "nopriv_user"              => "ftpsecure",
  "local_enable"             => "YES",
  "anonymous_enable"         => "YES",
  "anon_world_readable_only" => "YES",
  "syslog_enable"            => "YES",
  "connect_from_port_20"     => "YES",
  "ascii_upload_enable"      => "YES",
  "pam_service_name"         => "vsftpd",
  "listen"                   => "NO",
  "listen_ipv6"              => "YES",
  "ssl_enable"               => "NO",
  "pasv_min_port"            => "30000",
  "pasv_max_port"            => "30100"
}.freeze

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

  describe ".Write" do
    subject(:ftp_server) { Yast::FtpServerClass.new }

    before do
      allow(Yast::Progress).to receive(:New)
      allow(Yast::Progress).to receive(:NextStage)

      allow(Yast::Builtins).to receive(:sleep)

      allow(Yast2::SystemService).to receive(:find).with("vsftpd").and_return(service)

      allow(Yast::Mode).to receive(:auto) { auto }
      allow(Yast::Mode).to receive(:commandline) { commandline }

      allow(ftp_server).to receive(:PollAbort).and_return(false)
      allow(ftp_server).to receive(:WriteSettings).and_return(true)
      allow(ftp_server).to receive(:write_daemon)

      ftp_server.main
    end

    let(:service) { instance_double(Yast2::SystemService, save: true) }

    let(:auto) { false }
    let(:commandline) { false }

    shared_examples "old behavior" do
      it "does not save the system service" do
        expect(service).to_not receive(:save)

        ftp_server.Write
      end

      it "calls to :write_daemon" do
        expect(ftp_server).to receive(:write_daemon)

        ftp_server.Write
      end

      it "returns true" do
        expect(ftp_server.Write).to eq(true)
      end
    end

    context "when running in command line" do
      let(:commandline) { true }

      include_examples "old behavior"
    end

    context "when running in AutoYaST mode" do
      let(:auto) { true }

      include_examples "old behavior"
    end

    context "when running in normal mode" do
      it "does not call to :write_daemon" do
        expect(ftp_server).to_not receive(:write_daemon)

        ftp_server.Write
      end

      it "saves the system service" do
        expect(service).to receive(:save)

        ftp_server.Write
      end

      context "and the service is correctly saved" do
        before do
          allow(service).to receive(:save).and_return(true)
        end

        it "returns true" do
          expect(ftp_server.Write).to eq(true)
        end
      end

      context "and the service is not correctly saved" do
        before do
          allow(service).to receive(:save).and_return(false)
        end

        it "returns false" do
          expect(ftp_server.Write).to eq(false)
        end
      end
    end
  end
end
