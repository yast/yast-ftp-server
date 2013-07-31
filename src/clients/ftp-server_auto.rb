# encoding: utf-8

# File:	clients/ftp-server_auto.ycp
# Package:	Configuration of ftp-server
# Summary:	Client for autoinstallation
# Authors:	Jozef Uhliarik <juhliarik@suse.cz>
#
# $Id: ftp-server_auto.ycp 27914 2006-02-13 14:32:08Z locilka $
#
# This is a client for autoinstallation. It takes its arguments,
# goes through the configuration and return the setting.
# Does not do any changes to the configuration.

# @param function to execute
# @param map/list of ftp-server settings
# @return [Hash] edited settings, Summary or boolean on success depending on called function
# @example map mm = $[ "FAIL_DELAY" : "77" ];
# @example map ret = WFM::CallFunction ("ftp-server_auto", [ "Summary", mm ]);
module Yast
  class FtpServerAutoClient < Client
    def main
      Yast.import "UI"

      textdomain "ftp-server"

      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("FtpServer auto started")

      Yast.import "FtpServer"
      Yast.include self, "ftp-server/wizards.rb"

      @ret = nil
      @func = ""
      @param = {}

      # Check arguments
      if Ops.greater_than(Builtins.size(WFM.Args), 0) &&
          Ops.is_string?(WFM.Args(0))
        @func = Convert.to_string(WFM.Args(0))
        if Ops.greater_than(Builtins.size(WFM.Args), 1) &&
            Ops.is_map?(WFM.Args(1))
          @param = Convert.to_map(WFM.Args(1))
        end
      end
      Builtins.y2debug("func=%1", @func)
      Builtins.y2debug("param=%1", @param)

      # Create a summary
      if @func == "Summary"
        @ret = FtpServer.Summary 
        #ret = select(FtpServer::Summary(), 0, "");
      # Reset configuration
      elsif @func == "Reset"
        FtpServer.Import({})
        @ret = {}
      # Change configuration (run AutoSequence)
      elsif @func == "Change"
        @ret = FtpServerAutoSequence()
      # Import configuration
      elsif @func == "Import"
        @ret = FtpServer.Import(@param)
      # Return actual state
      elsif @func == "Export"
        @ret = FtpServer.Export
      # Return needed packages
      elsif @func == "Packages"
        @ret = FtpServer.AutoPackages
      # Return if configuration  was changed
      # return boolean
      elsif @func == "GetModified"
        @ret = FtpServer.modified
      # Set modified flag
      # return boolean
      elsif @func == "SetModified"
        FtpServer.modified = true
        @ret = true
      # Read current state
      elsif @func == "Read"
        Yast.import "Progress"
        @progress_orig = Progress.set(false)
        FtpServer.InitDaemon
        @ret = FtpServer.Read
        Progress.set(@progress_orig)
      # Write givven settings
      elsif @func == "Write"
        Yast.import "Progress"
        @progress_orig = Progress.set(false)
        FtpServer.write_only = true
        @ret = FtpServer.Write
        Progress.set(@progress_orig)
      else
        Builtins.y2error("Unknown function: %1", @func)
        @ret = false
      end

      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("FtpServer auto finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::FtpServerAutoClient.new.main
