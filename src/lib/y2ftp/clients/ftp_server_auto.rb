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

require "yast"

Yast.import "FtpServer"

module Y2Ftp
  module Clients
    # This is a client for autoinstallation. It takes its arguments, goes through the configuration and
    # return the setting. Does not do any changes to the configuration.
    #
    # @param function to execute
    # @param map/list of ftp-server settings
    # @return [Hash] edited settings, Summary or boolean on success depending on called function
    # @example map mm = $[ "FAIL_DELAY" : "77" ];
    # @example map ret = WFM::CallFunction ("ftp-server_auto", [ "Summary", mm ]);
    class FtpServerAuto < Yast::Client
      def initialize
        textdomain "ftp-server"

        Yast.include self, "ftp-server/wizards.rb"
      end

      def run
        Yast.import "UI"

        Yast::Builtins.y2milestone("----------------------------------------")
        Yast::Builtins.y2milestone("Yast::FtpServer auto started")

        @ret = nil
        @func = ""
        @param = {}

        # Check arguments
        if Yast::Ops.greater_than(Yast::Builtins.size(Yast::WFM.Args), 0) &&
            Yast::Ops.is_string?(Yast::WFM.Args(0))
          @func = Yast::Convert.to_string(Yast::WFM.Args(0))
          if Yast::Ops.greater_than(Yast::Builtins.size(Yast::WFM.Args), 1) &&
              Yast::Ops.is_map?(Yast::WFM.Args(1))
            @param = Yast::Convert.to_map(Yast::WFM.Args(1))
          end
        end
        Yast::Builtins.y2debug("func=%1", @func)
        Yast::Builtins.y2debug("param=%1", @param)

        # Create a summary
        if @func == "Summary"
          @ret = Yast::FtpServer.Summary
        # ret = select(Yast::FtpServer::Summary(), 0, "");
        # Reset configuration
        elsif @func == "Reset"
          Yast::FtpServer.Import({})
          @ret = {}
        # Change configuration (run AutoSequence)
        elsif @func == "Change"
          @ret = FtpServerAutoSequence()
        # Import configuration
        elsif @func == "Import"
          @ret = Yast::FtpServer.Import(@param)
        # Return actual state
        elsif @func == "Export"
          @ret = Yast::FtpServer.Export
        # Return needed packages
        elsif @func == "Packages"
          @ret = Yast::FtpServer.AutoPackages
        # Return if configuration  was changed
        # return boolean
        elsif @func == "GetModified"
          @ret = Yast::FtpServer.modified
        # Set modified flag
        # return boolean
        elsif @func == "SetModified"
          Yast::FtpServer.modified = true
          @ret = true
        # Read current state
        elsif @func == "Read"
          Yast.import "Progress"
          @progress_orig = Yast::Progress.set(false)
          Yast::FtpServer.InitDaemon
          @ret = Yast::FtpServer.Read
          Yast::Progress.set(@progress_orig)
        # Write given settings
        elsif @func == "Write"
          Yast.import "Progress"
          @progress_orig = Yast::Progress.set(false)
          Yast::FtpServer.write_only = true
          old_mode = Yast::Mode.mode
          if old_mode == "autoinst_config"
            # We are in the autoyast configuration module.
            # So there is currently no access to the target system.
            # This has to be done at first. (bnc#888212)
            Yast::Mode.SetMode("normal")
            Yast::FtpServer.InitDaemon
            Yast::FtpServer.read_daemon
          end
          @ret = Yast::FtpServer.Write
          Yast::Mode.SetMode(old_mode)
          Yast::Progress.set(@progress_orig)
        else
          Yast::Builtins.y2error("Unknown function: %1", @func)
          @ret = false
        end

        Yast::Builtins.y2debug("ret=%1", @ret)
        Yast::Builtins.y2milestone("Yast::FtpServer auto finished")
        Yast::Builtins.y2milestone("----------------------------------------")

        deep_copy(@ret)
      end
    end
  end
end
