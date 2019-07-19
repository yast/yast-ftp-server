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

require_relative "../../spec_helper.rb"
require "y2ftp/clients/ftp_server"

describe Y2Ftp::Clients::FtpServer do
  subject { described_class.new }

  describe "#FTPdCMDShow" do
    before do
      allow(Yast::FtpServer).to receive(:EDIT_SETTINGS).and_return("AnonAuthen" => anon_authen)
      allow(Yast::FtpServer).to receive(:main)

      allow(Yast::CommandLine).to receive(:Print)
    end

    context "when access is configured for anonymous users" do
      let(:anon_authen) { "0" }

      it "prints access for anonymous users" do
        expect(Yast::CommandLine).to receive(:Print).with(/Anonymous Users/)

        subject.FTPdCMDShow({})
      end
    end

    context "when access is configured for authenticated users" do
      let(:anon_authen) { "1" }

      it "prints access for authenticated users" do
        expect(Yast::CommandLine).to receive(:Print).with(/Authenticated Users/)

        subject.FTPdCMDShow({})
      end
    end

    context "when access is configured for anonymous and authenticated users" do
      let(:anon_authen) { "2" }

      it "prints access for anonymous and authenticated users" do
        expect(Yast::CommandLine).to receive(:Print).with(/Anonymous and Authenticated Users/)

        subject.FTPdCMDShow({})
      end
    end

    context "when access option has a wrong value" do
      let(:anon_authen) { "-1" }

      it "prints message about wrong value" do
        expect(Yast::CommandLine).to receive(:Print).with(/has wrong value/)

        subject.FTPdCMDShow({})
      end
    end
  end
end
