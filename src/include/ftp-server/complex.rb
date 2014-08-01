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


    # Init settings dialog (select the daemon)
    #
    # @return [Boolean] successfull

    def ReadFTPService
      #Checking if ftp daemons are installed
      rad_but = 0
      vsftpd_init_count = 0
      pureftpd_init_count = 0
      ret = nil
      vs_package_available = false
      pure_package_available = false


      if Package.Installed("vsftpd")
        vsftpd_init_count = Ops.add(vsftpd_init_count, 1)
        FtpServer.vsftpd_installed = true
      end

      if Package.Installed("pure-ftpd")
        pureftpd_init_count = Ops.add(pureftpd_init_count, 1)
        FtpServer.pureftpd_installed = true
      end


      if vsftpd_init_count == 0 && pureftpd_init_count == 0
        vs_package_available = Package.Available("vsftpd")
        pure_package_available = Package.Available("pure-ftpd")
        if !vs_package_available && !pure_package_available
          Popup.Error(_("Packages for vsftpd and pure-ftpd are not available."))
          Builtins.y2error(
            "[ftp-server] (ReadFTPService ()) Packages for vsftpd and pure-ftpd are not available."
          )
          return false
        end


        UI.OpenDialog(
          RadioButtonGroup(
            Id("IntstallFTPd"), # end of `VBox(
            VBox(
              Heading(_("No server package installed.")),
              Left(Label(_("Choose an FTP daemon."))),
              Left(Label(_("Press Cancel to cancel FTP configuration."))),
              Left(RadioButton(Id(0), Opt(:notify), _("&vsftpd"), true)),
              Left(RadioButton(Id(1), Opt(:notify), _("&pure-ftpd"))),
              ButtonBox(
                PushButton(Id(:accept), Label.OKButton),
                PushButton(Id(:cancel), Label.CancelButton)
              )
            )
          ) #end of `RadioButtonGroup(`id("IntstallFTPd")
        ) # end of UI::OpenDialog(
        if !vs_package_available
          UI.ChangeWidget(Id(0), :Enabled, false)
          UI.ChangeWidget(Id(1), :Value, true)
        end

        if !pure_package_available
          UI.ChangeWidget(Id(1), :Enabled, false)
          UI.ChangeWidget(Id(0), :Value, true)
        end
        install = 0
        while true
          ret = UI.UserInput
          if ret == :accept
            install = Convert.to_integer(
              UI.QueryWidget(Id("IntstallFTPd"), :CurrentButton)
            )
            break
          elsif ret == :cancel
            UI.CloseDialog
            Builtins.y2milestone("[ftp-server] Installation was aborted")
            return false
          end
        end
        UI.CloseDialog
        result = nil
        daemon_list = []
        daemon = ""
        if install == 0
          daemon = "vsftpd"
          daemon_list = Builtins.add(daemon_list, daemon)
          result = vs_package_available
        else
          daemon = "pure-ftpd"
          daemon_list = Builtins.add(daemon_list, daemon)
          result = pure_package_available
        end
        #result = Package::Available(daemon);
        if result == true
          result = Package.DoInstall(daemon_list)
          if result == false
            Popup.Error(_("Installation failed."))
            Builtins.y2milestone("[ftp-server] Installation failed")
            return false
          end
          if daemon == "pure-ftpd"
            FtpServer.pureftpd_installed = true
            pureftpd_init_count = Ops.add(pureftpd_init_count, 1)
          else
            FtpServer.vsftpd_installed = true
            vsftpd_init_count = Ops.add(vsftpd_init_count, 1)
          end
        elsif result == false
          Popup.Error(_("Package for FTP is not available."))
          Builtins.y2milestone("[ftp-server] Package for ftp is not available")
          return false
        elsif result == nil
          Popup.Error(_("Package not found."))
          Builtins.y2milestone("[ftp-server] Package was not found")
          return false
        end
      end #end of if ((vsftpd_init_count == 0) && (pureftpd_init_count == 0)) {

      #Checking Enabled services for ftp daemons

      if Service.Enabled("pure-ftpd")
        pureftpd_init_count = Ops.add(pureftpd_init_count, 1)
      end

      if Service.Enabled("vsftpd")
        vsftpd_init_count = Ops.add(vsftpd_init_count, 1)
      end

      #Checking status of ftp daemons

      if Service.Status("vsftpd") == 0
        FtpServer.vsftpd_edit = true
        vsftpd_init_count = Ops.add(vsftpd_init_count, 1)
      else
        FtpServer.vsftpd_edit = false
      end

      if Service.Status("pure-ftpd") == 0
        FtpServer.vsftpd_edit = false
        pureftpd_init_count = Ops.add(pureftpd_init_count, 1)
      else
        FtpServer.vsftpd_edit = true
      end

      # open dialog for choosing ftp daemon

      if pureftpd_init_count == vsftpd_init_count &&
          FtpServer.pureftpd_installed &&
          FtpServer.vsftpd_installed
        UI.OpenDialog(
          RadioButtonGroup(
            Id(:rb),
            VBox(
              Label(_("Choose daemon?")),
              Left(
                RadioButton(
                  Id(0),
                  Opt(:notify),
                  _("&vsftpd"),
                  FtpServer.vsftpd_edit ? true : false
                )
              ),
              Left(
                RadioButton(
                  Id(1),
                  Opt(:notify),
                  _("&pure-ftpd"),
                  FtpServer.vsftpd_edit ? false : true
                )
              ),
              ButtonBox(
                PushButton(Id(:close), Label.OKButton),
                PushButton(Id(:abort), Label.CancelButton)
              )
            )
          ) #end of `RadioButtonGroup(`id(`rb), `VBox(
        ) #end of UI::OpenDialog(

        while true
          ret = UI.UserInput
          if ret == :close
            rad_but = Convert.to_integer(
              UI.QueryWidget(Id(:rb), :CurrentButton)
            )
            break
          elsif ret == :abort
            return false
          end
        end #end of  while (true) {

        if rad_but == 0
          FtpServer.vsftpd_edit = true
        else
          FtpServer.vsftpd_edit = false
        end

        Builtins.y2milestone(
          "[ftp-server] Terminating by the radiobutom ID '%1'",
          rad_but
        )

        UI.CloseDialog
      else
        if FtpServer.pureftpd_installed && !FtpServer.vsftpd_installed
          FtpServer.vsftpd_edit = false
        end
        if !FtpServer.pureftpd_installed && FtpServer.vsftpd_installed
          FtpServer.vsftpd_edit = true
        end
      end
      true
    end



    # Read settings dialog
    # @return `abort if aborted and `next otherwise
    def ReadDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "read", ""))
      result = ReadFTPService()
      return :abort if !result
      return :abort if !Confirm.MustBeRoot
      ret = FtpServer.Read
      if FtpServer.vsftpd_edit && ret || !FtpServer.vsftpd_edit && ret
        return :next
      else
        return :abort
      end 

      #return ret ? `next : `abort;
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
