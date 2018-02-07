# encoding: utf-8

# File:	include/ftpd/complex.ycp
# Package:	Configuration of ftpd
# Summary:	Dialogs definitions
# Authors:	Jozef Uhliarik <juhliarik@suse.cz>
#
# $Id: complex.ycp 29363 2006-03-24 08:20:43Z juhliarik $
module Yast
  module FtpServerComplexInclude
    def initialize_ftp_server_complex(include_target)
      Yast.import "UI"

      textdomain "ftp-server"

      Yast.import "Label"
      Yast.import "Popup"
      Yast.import "Wizard"
      Yast.import "Confirm"
      Yast.import "FtpServer"
      Yast.import "Package"
      Yast.import "Service"
      Yast.include include_target, "ftp-server/helps.rb"
    end

    # Return a modification status
    # @return true if data was modified
    def Modified
      FtpServer.Modified
    end

    def ReallyAbort
      !FtpServer.Modified || Popup.ReallyAbort(true)
    end

    def PollAbort
      UI.PollInput == :abort
    end

    # Read settings dialog
    # @return `abort if aborted and `next otherwise
    def ReadDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "read", ""))
      return :abort if !Confirm.MustBeRoot
      ret = FtpServer.Read

      return ret ? :next : :abort
    end

    # Write settings dialog
    # @return `abort if aborted and `next otherwise
    def WriteDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "write", ""))
      ret = FtpServer.Write
      ret ? :next : :abort
    end
  end
end
