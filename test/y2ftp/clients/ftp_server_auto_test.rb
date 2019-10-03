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
require "y2ftp/clients/ftp_server_auto"

describe Y2Ftp::Clients::FtpServerAuto do
  subject { described_class.new }

  describe "#run" do
    context "Summary argument" do
      before do
        allow(Yast::WFM).to receive(:Args).with(no_args).and_return(["Summary"])
        allow(Yast::WFM).to receive(:Args).with(0).and_return("Summary")
      end

      it "returns string" do
        expect(subject.run).to be_a(::String)
      end
    end
  end
end
