# encoding: utf-8

# File:	include/ftp-server/wid_functions.ycp
# Package:	Configuration of ftp-server
# Summary:	Wizards definitions
# Authors:	Jozef Uhliarik <juhliarik@suse.cz>
#
# $Id: wid_functions.ycp 27914 2006-02-13 14:32:08Z juhliarik $
module Yast
  module FtpServerWidFunctionsInclude
    def initialize_ftp_server_wid_functions(include_target)
      Yast.import "UI"

      textdomain "ftp-server"

      Yast.import "Popup"
      Yast.import "Wizard"
      Yast.import "Service"
      Yast.import "Users"
      Yast.import "Mode"
      Yast.import "FileUtils"
      Yast.import "Label"
      Yast.import "FtpServer"


      #  variable signifies repeat asking about upload file
      #  only for vsftpd
      #
      # internal boolean variable
      @ask_again = true
    end

    # CWMServiceStart function with no parameter returning boolean value
    # that says if the service is started.
    def GetEnableService
      result = false
      if Ops.get(FtpServer.EDIT_SETTINGS, "StartDaemon") == "1"
        result = true
      else
        result = false
      end
      result
    end


    # CWMServiceStart function with one boolean parameter
    # returning boolean value that says if the service will be started at boot.
    def SetEnableService(enable_service)
      if Builtins.size(FtpServer.EDIT_SETTINGS) == 0
        FtpServer.EDIT_SETTINGS = deep_copy(FtpServer.DEFAULT_CONFIG)
      end

      if enable_service
        Ops.set(FtpServer.EDIT_SETTINGS, "StartDaemon", "1")
        Ops.set(FtpServer.EDIT_SETTINGS, "StartXinetd", "NO")
      end

      nil
    end

    # CWMServiceStart function with no parameter returning boolean value
    # that says if the service is started.
    def GetStartedViaXinetd
      result = false
      if Ops.get(FtpServer.EDIT_SETTINGS, "StartDaemon") == "2"
        result = true
      else
        result = false
      end


      result
    end


    def AskStartXinetd
      result = false

      if Service.Status("xinetd") != 0 &&
          Ops.get(FtpServer.EDIT_SETTINGS, "StartXinetd") == "NO"
        if Mode.normal
          UI.OpenDialog(
            VBox(
              Label(_("Xinetd is not running.")),
              Label(_("Start it now?")),
              ButtonBox(
                PushButton(Id(:accept), Label.OKButton),
                PushButton(Id(:cancel), Label.CancelButton)
              )
            )
          ) # end of UI::OpenDialog(
          while true
            ret = UI.UserInput
            if ret == :accept
              result = true
              break
            elsif ret == :cancel
              result = false
              break
            end
          end
          UI.CloseDialog
        end # end of if (Mode::normal()) {
      end # end of if ((Service::Status("xinetd") != 0)...

      result
    end

    # CWMServiceStart function with one boolean parameter
    # returning boolean value that says if the service will be started at boot.
    def SetStartedViaXinetd(enable_service)
      result = true
      if enable_service
        Ops.set(FtpServer.EDIT_SETTINGS, "StartDaemon", "2")
        result = AskStartXinetd()
        result = true if Service.Status("xinetd") == 0 if !result
        if result
          Ops.set(FtpServer.EDIT_SETTINGS, "StartXinetd", "YES")
        else
          Ops.set(FtpServer.EDIT_SETTINGS, "StartXinetd", "NO")
        end
      else
        Ops.set(FtpServer.EDIT_SETTINGS, "StartDaemon", "0")
        Ops.set(FtpServer.EDIT_SETTINGS, "StartXinetd", "NO")
      end

      nil
    end


    def UpdateInfoAboutStartingFTP
      #which radiobutton is selected for starting "when booting", "via xinetd" or "manually"
      value = UI.QueryWidget(Id("_cwm_service_startup"), :Value)

      if Builtins.tostring(value) == "_cwm_startup_manual"
        Ops.set(FtpServer.EDIT_SETTINGS, "StartDaemon", "0")
      elsif Builtins.tostring(value) == "_cwm_startup_auto"
        Ops.set(FtpServer.EDIT_SETTINGS, "StartDaemon", "1")
      else
        Ops.set(FtpServer.EDIT_SETTINGS, "StartDaemon", "2")
      end

      nil
    end


    # Function start vsftpd
    def StartNowVsftpd
      result = false

      UpdateInfoAboutStartingFTP()

      if Ops.get(FtpServer.EDIT_SETTINGS, "StartDaemon") == "2" &&
          Service.Status("pure-ftpd") != 0
        SCR.Write(Builtins.add(path(".vsftpd"), "listen"), nil)
        SCR.Write(Builtins.add(path(".vsftpd"), "listen_ipv6"), nil)
        SCR.Write(path(".vsftpd"), nil)
        FtpServer.stop_daemon_xinetd = false
        result = AskStartXinetd()

        if !result
          if Service.Status("xinetd") == 0 ||
              Ops.get(FtpServer.EDIT_SETTINGS, "StartXinetd") == "YES"
            result = true
          end
        end

        if FtpServer.WriteStartViaXinetd(true, true) && result
          FtpServer.vsftp_xinetd_running = true
          FtpServer.pure_ftp_xinetd_running = false
          UI.ReplaceWidget(
            Id("_cwm_service_status_rp"),
            Label(_("FTP is running"))
          )
          UI.ChangeWidget(Id("_cwm_start_service_now"), :Enabled, false)
          UI.ChangeWidget(Id("_cwm_stop_service_now"), :Enabled, true)
          result = true
        end
      else
        SCR.Write(Builtins.add(path(".vsftpd"), "listen"), "YES")
        SCR.Write(Builtins.add(path(".vsftpd"), "listen_ipv6"), nil)
        SCR.Write(path(".vsftpd"), nil)
        command = "rcvsftpd start"
        options = Convert.to_map(
          SCR.Execute(path(".target.bash_output"), command)
        )
        Builtins.y2milestone(
          "[ftp-server] (StartNowVsftpd) command for starting vsftpd:  %1  output: %2",
          command,
          options
        )
        if Ops.get(options, "exit") == 0
          result = true
        else
          result = false
        end
      end
      result
    end


    # Function stop vsftpd
    def StopNowVsftpd
      result = false

      #UpdateInfoAboutStartingFTP ();

      if FtpServer.vsftp_xinetd_running
        FtpServer.stop_daemon_xinetd = true
        if FtpServer.WriteStartViaXinetd(true, true)
          FtpServer.vsftp_xinetd_running = false
          UI.ReplaceWidget(
            Id("_cwm_service_status_rp"),
            Label(_("FTP is not running"))
          )
          UI.ChangeWidget(Id("_cwm_start_service_now"), :Enabled, true)
          UI.ChangeWidget(Id("_cwm_stop_service_now"), :Enabled, false)
          result = true
        end
      else
        command = "rcvsftpd stop"
        options = Convert.to_map(
          SCR.Execute(path(".target.bash_output"), command)
        )
        Builtins.y2milestone(
          "[ftp-server] (StopNowVsftpd) command for stop vsftpd:  %1  output: %2",
          command,
          options
        )
        if Ops.get(options, "exit") == 0
          result = true
        else
          result = false
        end
      end
      result
    end

    # Function saves configuration and restarts vsftpd
    def SaveAndRestartVsftpd
      result = false

      result = StopNowVsftpd()
      UpdateInfoAboutStartingFTP()

      if Ops.get(FtpServer.EDIT_SETTINGS, "StartDaemon") == "2" &&
          Service.Status("pure-ftpd") != 0
        result = AskStartXinetd()
        #write settings to disk...
        FtpServer.WriteSettings

        if !result
          if Service.Status("xinetd") == 0 ||
              Ops.get(FtpServer.EDIT_SETTINGS, "StartXinetd") == "YES"
            result = true
          end
        end
        FtpServer.stop_daemon_xinetd = false
        if FtpServer.WriteStartViaXinetd(true, false) && result
          FtpServer.vsftp_xinetd_running = true
          UI.ReplaceWidget(
            Id("_cwm_service_status_rp"),
            Label(_("FTP is running"))
          )
          UI.ChangeWidget(Id("_cwm_start_service_now"), :Enabled, false)
          UI.ChangeWidget(Id("_cwm_stop_service_now"), :Enabled, true)
          result = true
        end
      else
        FtpServer.WriteSettings
        command = "rcvsftpd start"
        options = Convert.to_map(
          SCR.Execute(path(".target.bash_output"), command)
        )
        Builtins.y2milestone(
          "[ftp-server] (SaveAndRestartVsftpd) command for save and restart vsftpd:  %1  output: %2",
          command,
          options
        )
        if Ops.get(options, "exit") == 0
          result = true
        else
          result = false
        end
      end
      FtpServer.WriteUpload
      result
    end




    # Function start pure-ftpd

    def StartNowPure
      result = false

      UpdateInfoAboutStartingFTP()

      if Ops.get(FtpServer.EDIT_SETTINGS, "StartDaemon") == "2" &&
          Service.Status("vsftpd") != 0
        FtpServer.stop_daemon_xinetd = false
        result = AskStartXinetd()

        if !result
          if Service.Status("xinetd") == 0 ||
              Ops.get(FtpServer.EDIT_SETTINGS, "StartXinetd") == "YES"
            result = true
          end
        end

        if FtpServer.WriteStartViaXinetd(true, true) && result
          FtpServer.pure_ftp_xinetd_running = true
          FtpServer.vsftp_xinetd_running = false
          UI.ReplaceWidget(
            Id("_cwm_service_status_rp"),
            Label(_("FTP is running"))
          )
          UI.ChangeWidget(Id("_cwm_start_service_now"), :Enabled, false)
          UI.ChangeWidget(Id("_cwm_stop_service_now"), :Enabled, true)
          result = true
        end
      else
        SCR.Write(Builtins.add(path(".pure-ftpd"), "Daemonize"), "YES")
        SCR.Write(path(".pure-ftpd"), nil)
        command = "rcpure-ftpd start"

        options = Convert.to_map(
          SCR.Execute(path(".target.bash_output"), command)
        )

        Builtins.y2milestone(
          "[ftp-server] (StartNowPure) command for start pure-ftpd:  %1  output: %2",
          command,
          options
        )

        if Ops.get(options, "exit") == 0
          result = true
        else
          result = false
        end
      end
      result
    end

    # Function stop pure-ftpd
    def StopNowPure
      result = false

      if FtpServer.pure_ftp_xinetd_running
        #Popup::Message(_("This is not supported via xinetd now."));

        FtpServer.stop_daemon_xinetd = true
        if FtpServer.WriteStartViaXinetd(true, true)
          FtpServer.pure_ftp_xinetd_running = false
          UI.ReplaceWidget(
            Id("_cwm_service_status_rp"),
            Label(_("FTP is not running"))
          )
          UI.ChangeWidget(Id("_cwm_start_service_now"), :Enabled, true)
          UI.ChangeWidget(Id("_cwm_stop_service_now"), :Enabled, false)
          result = true
        end
      else
        command = "rcpure-ftpd stop"
        options = Convert.to_map(
          SCR.Execute(path(".target.bash_output"), command)
        )
        Builtins.y2milestone(
          "[ftp-server] (StopNowPure) command for stop pure-ftpd:  %1  output: %2",
          command,
          options
        )
        if Ops.get(options, "exit") == 0
          result = true
        else
          result = false
        end
      end
      result
    end

    # Function saves configuration and restarts pure-ftpd
    def SaveAndRestartPure
      result = false

      result = StopNowPure()
      UpdateInfoAboutStartingFTP()

      if Ops.get(FtpServer.EDIT_SETTINGS, "StartDaemon") == "2" &&
          Service.Status("vsftpd") != 0
        result = AskStartXinetd()
        #write settings to disk...
        FtpServer.WriteSettings

        if !result
          if Service.Status("xinetd") == 0 ||
              Ops.get(FtpServer.EDIT_SETTINGS, "StartXinetd") == "YES"
            result = true
          end
        end
        FtpServer.stop_daemon_xinetd = false
        if FtpServer.WriteStartViaXinetd(true, false) && result
          FtpServer.pure_ftp_xinetd_running = true
          UI.ReplaceWidget(
            Id("_cwm_service_status_rp"),
            Label(_("FTP is running"))
          )
          UI.ChangeWidget(Id("_cwm_start_service_now"), :Enabled, false)
          UI.ChangeWidget(Id("_cwm_stop_service_now"), :Enabled, true)
          result = true
        end
      else
        #write settings to disk...
        FtpServer.WriteSettings
        command = "rcpure-ftpd start"
        options = Convert.to_map(
          SCR.Execute(path(".target.bash_output"), command)
        )
        Builtins.y2milestone(
          "[ftp-server] (StopNowPure) command for save and restart pure-ftpd:  %1  output: %2",
          command,
          options
        )
        if Ops.get(options, "exit") == 0
          result = true
        else
          result = false
        end
      end
      result = FtpServer.WriteUpload
      result
    end


    # Init function for general settings
    # save values to temporary structure
    def InitRBVsPure(key)
      if FtpServer.vsftpd_installed && FtpServer.pureftpd_installed
        if FtpServer.vsftpd_edit
          UI.ChangeWidget(Id("vs_item"), :Value, true)
        else
          UI.ChangeWidget(Id("pure_item"), :Value, true)
        end
      elsif FtpServer.vsftpd_installed && !FtpServer.pureftpd_installed
        UI.ChangeWidget(Id("vs_item"), :Value, true)
        UI.ChangeWidget(Id("pure_item"), :Enabled, false)
        UI.ChangeWidget(Id("vs_item"), :Enabled, false)
      elsif !FtpServer.vsftpd_installed && FtpServer.pureftpd_installed
        UI.ChangeWidget(Id("pure_item"), :Value, true)
        UI.ChangeWidget(Id("pure_item"), :Enabled, false)
        UI.ChangeWidget(Id("vs_item"), :Enabled, false)
      else
        UI.ChangeWidget(Id("pure_item"), :Enabled, false)
        UI.ChangeWidget(Id("vs_item"), :Enabled, false)
      end

      if !Mode.normal
        # Autoyast configuration module does not take care about installed
        # packages (installed ftp-servers). As we are using vsftpd
        # in autoyast (SLES) only, we are disabling the selection of
        # different ftp servers. (bnc#888212)
        if FtpServer.vsftpd_edit || Mode.config
          UI.ChangeWidget(Id("vs_item"), :Value, true)
        else
          UI.ChangeWidget(Id("pure_item"), :Value, true)
        end
        UI.ChangeWidget(Id("pure_item"), :Enabled, false)
        UI.ChangeWidget(Id("vs_item"), :Enabled, false)
      end

      nil
    end


    def HandleRBVsPure(key, event)
      event = deep_copy(event)
      if FtpServer.vsftpd_edit &&
          Convert.to_boolean(UI.QueryWidget(Id("pure_item"), :Value)) &&
          FtpServer.vsftpd_installed
        FtpServer.vsftpd_edit = false
        return :pureftpd
      end
      if !FtpServer.vsftpd_edit &&
          Convert.to_boolean(UI.QueryWidget(Id("vs_item"), :Value)) &&
          FtpServer.pureftpd_installed
        FtpServer.vsftpd_edit = true
        return :vsftpd
      end

      nil
    end

    # Init function for start-up
    #
    # init starting via xinetd and update status
    def InitStartStopRestart(key)
      if FtpServer.pure_ftp_xinetd_running && !FtpServer.vsftpd_edit
        UI.ReplaceWidget(
          Id("_cwm_service_status_rp"),
          Label(_("FTP is running"))
        )
        UI.ChangeWidget(Id("_cwm_start_service_now"), :Enabled, false)
        UI.ChangeWidget(Id("_cwm_stop_service_now"), :Enabled, true)
      end

      if FtpServer.vsftp_xinetd_running && FtpServer.vsftpd_edit
        UI.ReplaceWidget(
          Id("_cwm_service_status_rp"),
          Label(_("FTP is running"))
        )
        UI.ChangeWidget(Id("_cwm_start_service_now"), :Enabled, false)
        UI.ChangeWidget(Id("_cwm_stop_service_now"), :Enabled, true)
      end

      nil
    end

    #-----------================= GENERAL SCREEN =============----------
    #

    # Init function "Wellcome Message" for general settings
    # change ValidChars for textentry
    # only vsftpd
    def InitBanner(key)
      UI.ChangeWidget(Id("Banner"), :Value, FtpServer.ValueUIEdit("Banner"))

      nil
    end

    # Handle function only save info about changes
    def HandleUniversal(key, event)
      event = deep_copy(event)
      # modified
      if Ops.get_string(event, "EventReason", "") == "ValueChanged"
        FtpServer.SetModified(true)
      end
      nil
    end

    # Store function of "Wellcome Message"
    # save values to temporary structure
    # only vsftpd
    def StoreBanner(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "Banner",
        Builtins.tostring(UI.QueryWidget(Id("Banner"), :Value))
      )

      nil
    end

    # Init function "Chroot Everyone" for general settings
    # check_box
    def InitChrootEnable(key)
      UI.ChangeWidget(
        Id("ChrootEnable"),
        :Value,
        FtpServer.ValueUIEdit("ChrootEnable") == "YES"
      )

      nil
    end

    # Store function of "Chroot Everyone"
    # save values to temporary structure
    def StoreChrootEnable(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "ChrootEnable",
        Convert.to_boolean(UI.QueryWidget(Id("ChrootEnable"), :Value)) == true ? "YES" : "NO"
      )

      nil
    end

    # Init function "Verbose Logging" for general settings
    # check_box
    def InitVerboseLogging(key)
      UI.ChangeWidget(
        Id("VerboseLogging"),
        :Value,
        FtpServer.ValueUIEdit("VerboseLogging") == "YES"
      )

      nil
    end

    # Store function of "Verbose Logging"
    # save values to temporary structure
    def StoreVerboseLogging(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "VerboseLogging",
        Convert.to_boolean(UI.QueryWidget(Id("VerboseLogging"), :Value)) == true ? "YES" : "NO"
      )

      nil
    end

    # Init function "Umask (umask files:umask dirs)" for general settings
    # change ValidChars for textentry
    # only pure-ftpd
    def InitUmask(key)
      UI.ChangeWidget(Id("Umask"), :ValidChars, "01234567:")
      UI.ChangeWidget(Id("Umask"), :Value, FtpServer.ValueUIEdit("Umask"))

      nil
    end

    # Valid function of "Umask (umask files:umask dirs)"
    # check value of textentry
    # only pure-ftpd
    def ValidUmask(key, event)
      event = deep_copy(event)
      new_umask = Convert.to_string(UI.QueryWidget(Id("Umask"), :Value))
      if Ops.greater_than(Builtins.size(new_umask), 0)
        l = Builtins.splitstring(new_umask, ":")
        l = Builtins.filter(l) { |s| s != "" }
        if Ops.less_than(Builtins.size(l), 2)
          Popup.Message(_("Not a valid umask."))
          UI.SetFocus(Id("Umask"))
          return false
        end
      end
      true
    end


    # Store function of "Umask (umask files:umask dirs)"
    # save values to temporary structure
    # only pure-ftpd
    def StoreUmask(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "Umask",
        Builtins.tostring(UI.QueryWidget(Id("Umask"), :Value))
      )

      nil
    end

    # Init function "Umask for Anonymous" for general settings
    # change ValidChars for textentry
    # only vsftpd
    def InitUmaskAnon(key)
      UI.ChangeWidget(Id("UmaskAnon"), :ValidChars, "01234567")
      UI.ChangeWidget(
        Id("UmaskAnon"),
        :Value,
        FtpServer.ValueUIEdit("UmaskAnon")
      )

      nil
    end


    # Store function of "Umask for Anonymous"
    # save values to temporary structure
    # only vsftpd
    def StoreUmaskAnon(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "UmaskAnon",
        Builtins.tostring(UI.QueryWidget(Id("UmaskAnon"), :Value))
      )

      nil
    end


    # Init function "Umask for Authenticated Users" for general settings
    # change ValidChars for textentry
    # only vsftpd
    def InitUmaskLocal(key)
      UI.ChangeWidget(Id("UmaskLocal"), :ValidChars, "01234567")
      UI.ChangeWidget(
        Id("UmaskLocal"),
        :Value,
        FtpServer.ValueUIEdit("UmaskLocal")
      )

      nil
    end

    # Store function of "Umask for Authenticated Users"
    # save values to temporary structure
    # only vsftpd
    def StoreUmaskLocal(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "UmaskLocal",
        Builtins.tostring(UI.QueryWidget(Id("UmaskLocal"), :Value))
      )

      nil
    end

    # Init function of "Ftp Directory for Anonymous Users"
    # textentry
    #
    def InitFtpDirAnon(key)
      if Ops.get(FtpServer.EDIT_SETTINGS, "VirtualUser") == "YES"
        UI.ChangeWidget(Id("FtpDirAnon"), :Enabled, false)
        UI.ChangeWidget(Id("BrowseAnon"), :Enabled, false)
      else
        UI.ChangeWidget(
          Id("FtpDirAnon"),
          :Value,
          FtpServer.ValueUIEdit("FtpDirAnon")
        )
      end

      nil
    end


    # Valid function of "Ftp Directory for Anon&ymous Users"
    # check value of textentry
    #
    def ValidFtpDirAnon(key, event)
      event = deep_copy(event)
      if !FtpServer.vsftpd_edit
        if Ops.get(FtpServer.EDIT_SETTINGS, "VirtualUser") == "NO"
          _AnonHomeDir = Convert.to_string(
            UI.QueryWidget(Id("FtpDirAnon"), :Value)
          )
          #checking correct homedir for anonymous user
          if _AnonHomeDir != "" && Mode.normal
            if _AnonHomeDir != FtpServer.anon_homedir
              error = Users.EditUser({ "homeDirectory" => _AnonHomeDir })
              if error != nil && error != ""
                Popup.Error(error)
                UI.SetFocus(Id("FtpDirAnon"))
                return false
              end
              uid = FtpServer.anon_uid
              failed = false
              ui_map = {}
              error_map = {}
              begin
                error_map = Users.CheckHomeUI(uid, _AnonHomeDir, ui_map)
                if error_map != {}
                  if !Popup.YesNo(Ops.get_string(error_map, "question", ""))
                    failed = true
                  else
                    Ops.set(
                      ui_map,
                      Ops.get_string(error_map, "question_id", ""),
                      _AnonHomeDir
                    )
                  end
                end
              end while error_map != {} && !failed
            end #end of if (AnonHomeDir != FtpServer::anon_homedir) {
          end #end of if ((AnonHomeDir != "") && (Mode::normal())) {
        end #end of if (FtpServer::EDIT_SETTINGS["VirtualUser"]:nil != "NO") {
      end #end of if (!FtpServer::vsftpd_edit) {
      true
    end

    # Store function of "Ftp Directory for Anon&ymous Users"
    # save values to temporary structure
    #
    def StoreFtpDirAnon(key, event)
      event = deep_copy(event)
      if Ops.get(FtpServer.EDIT_SETTINGS, "VirtualUser") == "NO"
        FtpServer.WriteToEditMap(
          "FtpDirAnon",
          Builtins.tostring(UI.QueryWidget(Id("FtpDirAnon"), :Value))
        )
      end

      nil
    end

    # Handle function of "Browse"
    # handling value in textentry of "Umask for Anonynmous Users"
    def HandleBrowseAnon(key, event)
      event = deep_copy(event)
      button = Ops.get(event, "ID")
      if button == "BrowseAnon"
        val = UI.AskForExistingDirectory("/", _("Select directory"))
        UI.ChangeWidget(Id("FtpDirAnon"), :Value, val) if val
      end
      nil
    end

    # Init function of "Ftp Directory for Authenticated Users"
    # textentry
    #
    def InitFtpDirLocal(key)
      UI.ChangeWidget(
        Id("FtpDirLocal"),
        :Value,
        FtpServer.ValueUIEdit("FtpDirLocal")
      )

      nil
    end

    # Store function of "Umask for Authenticated Users"
    # save values to temporary structure
    #
    def StoreFtpDirLocal(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "FtpDirLocal",
        Builtins.tostring(UI.QueryWidget(Id("FtpDirLocal"), :Value))
      )

      nil
    end

    # Handle function of "Browse"
    # handling value in textentry of "Umask for Authenticated Users"
    def HandleBrowseLocal(key, event)
      event = deep_copy(event)
      button = Ops.get(event, "ID")
      if button == "BrowseLocal"
        val = UI.AskForExistingDirectory("/", _("Select directory"))
        UI.ChangeWidget(Id("FtpDirLocal"), :Value, val) if val
      end
      nil
    end


    #-----------================= PERFORMANCE SCREEN =============----------
    #

    # Init function of "Max Idle Time [minutes]"
    # intfield
    #
    def InitMaxIdleTime(key)
      UI.ChangeWidget(
        Id("MaxIdleTime"),
        :Value,
        Builtins.tointeger(FtpServer.ValueUIEdit("MaxIdleTime"))
      )

      nil
    end

    # Store function of "Max Idle Time [minutes]"
    # save values to temporary structure
    #
    def StoreMaxIdleTime(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "MaxIdleTime",
        Builtins.tostring(UI.QueryWidget(Id("MaxIdleTime"), :Value))
      )

      nil
    end


    # Init function of "Max Clients for One IP"
    # intfield
    #
    def InitMaxClientsPerIP(key)
      UI.ChangeWidget(
        Id("MaxClientsPerIP"),
        :Value,
        Builtins.tointeger(FtpServer.ValueUIEdit("MaxClientsPerIP"))
      )

      nil
    end

    # Store function of "Max Clients for One IP"
    # save values to temporary structure
    #
    def StoreMaxClientsPerIP(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "MaxClientsPerIP",
        Builtins.tostring(UI.QueryWidget(Id("MaxClientsPerIP"), :Value))
      )

      nil
    end


    # Init function of "Max Clients"
    # intfield
    #
    def InitMaxClientsNumber(key)
      UI.ChangeWidget(
        Id("MaxClientsNumber"),
        :Value,
        Builtins.tointeger(FtpServer.ValueUIEdit("MaxClientsNumber"))
      )

      nil
    end

    # Store function of "Max Clients"
    # save values to temporary structure
    #
    def StoreMaxClientsNumber(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "MaxClientsNumber",
        Builtins.tostring(UI.QueryWidget(Id("MaxClientsNumber"), :Value))
      )

      nil
    end


    # Init function of "Local Max Rate [KB/s]"
    # intfield
    #
    def InitLocalMaxRate(key)
      UI.ChangeWidget(
        Id("LocalMaxRate"),
        :Value,
        Builtins.tointeger(FtpServer.ValueUIEdit("LocalMaxRate"))
      )

      nil
    end

    # Store function of "Local Max Rate [KB/s]"
    # save values to temporary structure
    #
    def StoreLocalMaxRate(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "LocalMaxRate",
        Builtins.tostring(UI.QueryWidget(Id("LocalMaxRate"), :Value))
      )

      nil
    end

    # Init function of "Anonymous Max Rate [KB/s]"
    # intfield
    #
    def InitAnonMaxRate(key)
      UI.ChangeWidget(
        Id("AnonMaxRate"),
        :Value,
        Builtins.tointeger(FtpServer.ValueUIEdit("AnonMaxRate"))
      )

      nil
    end

    # Store function of "Anonymous Max Rate [KB/s]"
    # save values to temporary structure
    #
    def StoreAnonMaxRate(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "AnonMaxRate",
        Builtins.tostring(UI.QueryWidget(Id("AnonMaxRate"), :Value))
      )

      nil
    end


    #-----------================= Authentication SCREEN =============----------
    #

    # Init function of "Enable/Disable Anonymous and Local Users"
    # radiobuttongroup
    #
    def InitAnonAuthen(key)
      authentication = Builtins.tointeger(FtpServer.ValueUIEdit("AnonAuthen"))
      if authentication == 0
        UI.ChangeWidget(Id("AnonAuthen"), :Value, "anon_only")
      elsif authentication == 1
        UI.ChangeWidget(Id("AnonAuthen"), :Value, "local_only")
      else
        UI.ChangeWidget(Id("AnonAuthen"), :Value, "both")
      end

      nil
    end

    # Store function of "Enable/Disable Anonymous and Local Users"
    # save value to temporary structure
    #
    def StoreAnonAuthen(key, event)
      event = deep_copy(event)
      radiobut = Convert.to_string(UI.QueryWidget(Id("AnonAuthen"), :Value))
      if radiobut == "anon_only"
        FtpServer.WriteToEditMap("AnonAuthen", "0")
      elsif radiobut == "local_only"
        FtpServer.WriteToEditMap("AnonAuthen", "1")
      else
        FtpServer.WriteToEditMap("AnonAuthen", "2")
      end

      nil
    end


    # Init function of "Enable Upload"
    # checkbox
    #
    def InitEnableUpload(key)
      UI.ChangeWidget(Id("EnableUpload"), :Notify, true)
      if FtpServer.ValueUIEdit("EnableUpload") == "YES"
        UI.ChangeWidget(Id("EnableUpload"), :Value, true)
        UI.ChangeWidget(Id("AnonReadOnly"), :Enabled, true)
        UI.ChangeWidget(Id("AnonCreatDirs"), :Enabled, true)
      else
        UI.ChangeWidget(Id("EnableUpload"), :Value, false)
        UI.ChangeWidget(Id("AnonReadOnly"), :Enabled, false)
        UI.ChangeWidget(Id("AnonCreatDirs"), :Enabled, false)
      end

      nil
    end


    # Handle function of "Enable Upload"
    # handling value and ask for creation upload directory
    # function also disable/enable "Anon&ymous Can Upload" and
    # "Anonymou&s Can Create Directories"
    def HandleEnableUpload(key, event)
      event = deep_copy(event)
      button = Ops.get(event, "ID")
      #Popup::Message("Hello world");
      if Mode.normal
        anon_upload = false
        anon_create_dirs = false
        yesno_comment = ""
        yesno_question = ""
        check_upload = Convert.to_boolean(
          UI.QueryWidget(Id("EnableUpload"), :Value)
        )
        if button == "EnableUpload"
          if check_upload
            UI.ChangeWidget(Id("AnonReadOnly"), :Enabled, true)
            UI.ChangeWidget(Id("AnonCreatDirs"), :Enabled, true)
          else
            UI.ChangeWidget(Id("AnonReadOnly"), :Enabled, false)
            UI.ChangeWidget(Id("AnonCreatDirs"), :Enabled, false)
          end
        end # end of if (button == "EnableUpload") {

        anon_upload = Convert.to_boolean(
          UI.QueryWidget(Id("AnonReadOnly"), :Value)
        )
        anon_create_dirs = Convert.to_boolean(
          UI.QueryWidget(Id("AnonCreatDirs"), :Value)
        )

        if (button == "AnonReadOnly" || anon_upload && check_upload) && @ask_again
          if !FtpServer.create_upload_dir
            yesno_question = Builtins.sformat(
              _("Create the \"upload\" directory in %1\n"),
              FtpServer.anon_homedir
            )
            yesno_question = Ops.add(
              yesno_question,
              _("and enable write access?\n")
            )
            yesno_comment = _(
              "If you want anonymous users to be able to upload,\n" +
                " you need to create a directory with write access.\n" +
                "\n"
            )
            yesno_comment = Ops.add(
              Ops.add(yesno_comment, FtpServer.anon_homedir),
              _(" is a home directory after the login of anonymous users.")
            )
            FtpServer.create_upload_dir = Popup.YesNoHeadline(
              yesno_question,
              yesno_comment
            )
            @ask_again = FtpServer.create_upload_dir
            FtpServer.upload_good_permission = true
          elsif !FtpServer.upload_good_permission
            yesno_question = Ops.add(
              Ops.add(
                _("Do you want to change permissions\nfor\n"),
                FtpServer.anon_homedir
              ),
              _("Upload (allow writing)?")
            )
            yesno_comment = _(
              "To allow anonymous users to upload, you need a directory with write access.\n\n"
            )
            yesno_comment = Ops.add(
              Ops.add(yesno_comment, FtpServer.anon_homedir),
              _(" is a home directory after the login of anonymous users.")
            )
            FtpServer.upload_good_permission = Popup.YesNoHeadline(
              yesno_question,
              yesno_comment
            )
            @ask_again = FtpServer.upload_good_permission
          end
        end

        if (button == "AnonCreatDirs" || anon_create_dirs && check_upload) && @ask_again
          if !FtpServer.create_upload_dir
            yesno_question = Ops.add(
              Ops.add(
                _("Do you want to create a directory?\n"),
                FtpServer.anon_homedir
              ),
              _("Upload with write access?")
            )
            yesno_comment = _(
              "If you want to allow anonymous users to create directories,\n" +
                " you have to create a directory with write access.\n" +
                "\n"
            )
            yesno_comment = Ops.add(
              Ops.add(yesno_comment, FtpServer.anon_homedir),
              _(" is a home directory after the login of anonymous users.")
            )
            FtpServer.create_upload_dir = Popup.YesNoHeadline(
              yesno_question,
              yesno_comment
            )
            @ask_again = FtpServer.create_upload_dir
            FtpServer.upload_good_permission = true
          elsif !FtpServer.upload_good_permission
            yesno_question = Ops.add(
              Ops.add(
                _("Do you want to change permissions\nfor\n"),
                FtpServer.anon_homedir
              ),
              _("Upload (allow writing)?")
            )
            yesno_comment = _(
              "If you want anonymous users to be able to create directories,\n" +
                " you need a directory with write access.\n" +
                "\n"
            )
            yesno_comment = Ops.add(
              Ops.add(yesno_comment, FtpServer.anon_homedir),
              _(" is a home directory after the login of anonymous users.")
            )
            FtpServer.upload_good_permission = Popup.YesNoHeadline(
              yesno_question,
              yesno_comment
            )
            @ask_again = FtpServer.upload_good_permission
          end
        end
      end # end of if (Mode::normal()) {
      # modified
      if Ops.get_string(event, "EventReason", "") == "ValueChanged"
        FtpServer.SetModified(true)
      end

      nil
    end

    # Store function of "Enable Upload"
    # save value to temporary structure
    #
    def StoreEnableUpload(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "EnableUpload",
        Convert.to_boolean(UI.QueryWidget(Id("EnableUpload"), :Value)) == true ? "YES" : "NO"
      )

      nil
    end



    # Init function of "Anonymous Can Upload"
    # checkbox
    #
    def InitAnonReadOnly(key)
      UI.ChangeWidget(
        Id("AnonReadOnly"),
        :Value,
        FtpServer.ValueUIEdit("AnonReadOnly") == "NO"
      )

      nil
    end

    # Handle function of "Anonymous Can Upload"
    # check permissions for upload dir
    #
    def HandleAnonReadOnly(key, event)
      event = deep_copy(event)
      yesno_comment = ""
      yesno_question = ""
      result = false
      enable = Convert.to_boolean(UI.QueryWidget(Id("AnonReadOnly"), :Value))

      if enable
        if !FtpServer.vsftpd_edit
          if FtpServer.pure_ftp_allowed_permissios_upload == 0
            yesno_question = Builtins.sformat(
              _("Change permissions of %1 ?\n"),
              FtpServer.anon_homedir
            )
            yesno_comment = Builtins.sformat(
              _(
                "If you want to allow uploads for \"anonymous\" users, \nyou need a directory with write access for them."
              )
            )
            result = Popup.YesNoHeadline(yesno_question, yesno_comment)
            if result
              FtpServer.pure_ftp_allowed_permissios_upload = 1
              FtpServer.change_permissions = true
            else
              FtpServer.pure_ftp_allowed_permissios_upload = -1
              FtpServer.change_permissions = false
            end
          end #end of if (FtpServer::pure_ftp_allowed_permissios_upload == 0)
        else
          if FtpServer.pure_ftp_allowed_permissios_upload == 1
            yesno_question = Builtins.sformat(
              _("Change permissions of %1 ?\n"),
              FtpServer.anon_homedir
            )
            yesno_comment = Builtins.sformat(
              _(
                "For anonymous connections the home directory of an anonymous user should have no write access.\n"
              )
            )
            result = Popup.YesNoHeadline(yesno_question, yesno_comment)
            if result
              FtpServer.pure_ftp_allowed_permissios_upload = 0
              FtpServer.change_permissions = true
            else
              FtpServer.pure_ftp_allowed_permissios_upload = -1
              FtpServer.change_permissions = false
            end
          end #end of if (FtpServer::pure_ftp_allowed_permissios_upload == 1)
        end #end else for if if (!FtpServer::vsftpd_edit) {
      end # end of if (enable) {
      # modified
      if Ops.get_string(event, "EventReason", "") == "ValueChanged"
        FtpServer.SetModified(true)
      end

      nil
    end

    # Store function of "Anonymous Can Upload"
    # save value to temporary structure
    #
    def StoreAnonReadOnly(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "AnonReadOnly",
        Convert.to_boolean(UI.QueryWidget(Id("AnonReadOnly"), :Value)) == true ? "NO" : "YES"
      )

      nil
    end

    # Init function of "Anonymous Can Create Directories"
    # checkbox
    #
    def InitAnonCreatDirs(key)
      UI.ChangeWidget(
        Id("AnonCreatDirs"),
        :Value,
        FtpServer.ValueUIEdit("AnonCreatDirs") == "YES"
      )

      nil
    end

    # Handle function of "Anonymous Can Create Directories"
    # check permissions for upload dir
    #
    def HandleAnonCreatDirs(key, event)
      event = deep_copy(event)
      yesno_comment = ""
      yesno_question = ""
      result = false
      enable = Convert.to_boolean(UI.QueryWidget(Id("AnonReadOnly"), :Value))

      if enable
        if !FtpServer.vsftpd_edit
          if FtpServer.pure_ftp_allowed_permissios_upload == 0
            yesno_question = Builtins.sformat(
              _("Change permissions of %1 ?\n"),
              FtpServer.anon_homedir
            )
            yesno_comment = Builtins.sformat(
              _(
                "If you want to allow uploads for \"anonymous\" users, \nyou need a directory with write access for them."
              )
            )
            result = Popup.YesNoHeadline(yesno_question, yesno_comment)
            if result
              FtpServer.pure_ftp_allowed_permissios_upload = 1
              FtpServer.change_permissions = true
            else
              FtpServer.pure_ftp_allowed_permissios_upload = -1
              FtpServer.change_permissions = false
            end
          end #end of if (FtpServer::pure_ftp_allowed_permissios_upload == 0)
        else
          if FtpServer.pure_ftp_allowed_permissios_upload == 1
            yesno_question = Builtins.sformat(
              _("Change permissions of %1 ?\n"),
              FtpServer.anon_homedir
            )
            yesno_comment = Builtins.sformat(
              _(
                "For anonymous connections the home directory of an anonymous user should have no write access."
              )
            )
            result = Popup.YesNoHeadline(yesno_question, yesno_comment)
            if result
              FtpServer.pure_ftp_allowed_permissios_upload = 0
              FtpServer.change_permissions = true
            else
              FtpServer.pure_ftp_allowed_permissios_upload = -1
              FtpServer.change_permissions = false
            end
          end #end of if (FtpServer::pure_ftp_allowed_permissios_upload == 1)
        end #end else for if if (!FtpServer::vsftpd_edit) {
      end # end of if (enable) {
      # modified
      if Ops.get_string(event, "EventReason", "") == "ValueChanged"
        FtpServer.SetModified(true)
      end

      nil
    end

    # Store function of "Anonymous Can Create Directories"
    # save value to temporary structure
    #
    def StoreAnonCreatDirs(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "AnonCreatDirs",
        Convert.to_boolean(UI.QueryWidget(Id("AnonCreatDirs"), :Value)) == true ? "YES" : "NO"
      )

      nil
    end


    #-----------================= EXPERT SETTINGS SCREEN =============----------
    #


    # Init function of "Enable Passive Mode"
    # checkbox
    #
    # also include handling enable/disable Min and Max Ports
    # handling intfields
    def InitPassiveMode(key)
      UI.ChangeWidget(Id("PassiveMode"), :Notify, true)
      UI.ChangeWidget(
        Id("PassiveMode"),
        :Value,
        FtpServer.ValueUIEdit("PassiveMode") == "YES"
      )

      nil
    end


    # Handle function of "Enable Passive Mode"
    # handling enable/disable widgets
    def HandlePassiveMode(key, event)
      event = deep_copy(event)
      value = Convert.to_boolean(UI.QueryWidget(Id("PassiveMode"), :Value))
      if value
        UI.ChangeWidget(Id("PasMinPort"), :Enabled, true)
        UI.ChangeWidget(Id("PasMaxPort"), :Enabled, true)
      else
        UI.ChangeWidget(Id("PasMinPort"), :Enabled, false)
        UI.ChangeWidget(Id("PasMaxPort"), :Enabled, false)
      end
      # modified
      if Ops.get_string(event, "EventReason", "") == "ValueChanged"
        FtpServer.SetModified(true)
      end

      nil
    end

    # Store function of "Enable Passive Mode"
    # save values to temporary structure
    #
    def StorePassiveMode(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "PassiveMode",
        Convert.to_boolean(UI.QueryWidget(Id("PassiveMode"), :Value)) == true ? "YES" : "NO"
      )

      nil
    end

    # Init function of "Min Port for Pas. Mode"
    # intfield
    #
    def InitPasMinPort(key)
      UI.ChangeWidget(
        Id("PasMinPort"),
        :Value,
        Builtins.tointeger(FtpServer.ValueUIEdit("PasMinPort"))
      )

      nil
    end

    # Store function of "Min Port for Pas. Mode"
    # save values to temporary structure
    #
    def StorePasMinPort(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "PasMinPort",
        Builtins.tostring(UI.QueryWidget(Id("PasMinPort"), :Value))
      )
      FtpServer.WriteToEditMap(
        "PassiveMode",
        Convert.to_boolean(UI.QueryWidget(Id("PassiveMode"), :Value)) == true ? "YES" : "NO"
      )

      nil
    end

    # Init function of "Max Port for Pas. Mode"
    # intfield
    #
    def InitPasMaxPort(key)
      UI.ChangeWidget(
        Id("PasMaxPort"),
        :Value,
        Builtins.tointeger(FtpServer.ValueUIEdit("PasMaxPort"))
      )

      nil
    end

    # Valid function of "Max Port for Pas. Mode"
    # check values Max Port >= Min Port
    #
    def ValidPasMaxPort(key, event)
      event = deep_copy(event)
      min_port = Builtins.tointeger(UI.QueryWidget(Id("PasMinPort"), :Value))
      max_port = Builtins.tointeger(UI.QueryWidget(Id("PasMaxPort"), :Value))

      if Ops.greater_than(min_port, max_port)
        Popup.Message(_("Condition for ports is max port > min port."))
        UI.SetFocus(Id("PasMinPort"))
        return false
      end
      true
    end

    # Store function of "Max Port for Pas. Mode"
    # save values to temporary structure
    #
    def StorePasMaxPort(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "PasMaxPort",
        Builtins.tostring(UI.QueryWidget(Id("PasMaxPort"), :Value))
      )

      nil
    end

    # Init function of "Enable SSL"
    # checkbox
    #
    # also include handling enable/disable SSL v2/3/TLS and Certificate
    # handling checkboxes and textentry
    def InitSSLEnable(key)
      UI.ChangeWidget(Id("SSLEnable"), :Notify, true)
      UI.ChangeWidget(
        Id("SSLEnable"),
        :Value,
        FtpServer.ValueUIEdit("SSLEnable") == "YES"
      )

      nil
    end

    # Handle function of "Enable SSL"
    # handling enable/disable widgets"
    def HandleSSLEnable(key, event)
      event = deep_copy(event)
      value = Convert.to_boolean(UI.QueryWidget(Id("SSLEnable"), :Value))
      if value
        UI.ChangeWidget(Id("TLS"), :Enabled, true)
        UI.ChangeWidget(Id("CertFile"), :Enabled, true)
        UI.ChangeWidget(Id("BrowseCertFile"), :Enabled, true)
      else
        UI.ChangeWidget(Id("TLS"), :Enabled, false)
        UI.ChangeWidget(Id("CertFile"), :Enabled, false)
        UI.ChangeWidget(Id("BrowseCertFile"), :Enabled, false)
      end
      # modified
      if Ops.get_string(event, "EventReason", "") == "ValueChanged"
        FtpServer.SetModified(true)
      end

      nil
    end


    # Store function of "Enable SSL"
    # save values to temporary structure
    #
    def StoreSSLEnable(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "SSLEnable",
        Convert.to_boolean(UI.QueryWidget(Id("SSLEnable"), :Value)) == true ? "YES" : "NO"
      )

      nil
    end

    # Init function of "Enable TLS"
    # intfield
    #
    def InitTLS(key)
      UI.ChangeWidget(Id("TLS"), :Value, FtpServer.ValueUIEdit("TLS") == "YES")

      nil
    end

    # Store function of "Enable TLS"
    # save value to temporary structure
    #
    def StoreTLS(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "TLS",
        Convert.to_boolean(UI.QueryWidget(Id("TLS"), :Value)) == true ? "YES" : "NO"
      )

      nil
    end

    # Init function of "RSA Certificate to Use for SSL Encrypted Connections"
    # intfield
    #
    def InitCertFile(key)
      UI.ChangeWidget(Id("CertFile"), :Value, FtpServer.ValueUIEdit("CertFile"))

      nil
    end

    # Valid function of "RSA Certificate to Use for SSL Encrypted Connections"
    # check value if user enable SSL Certificate (textentry) doesn't be empty
    #
    def ValidCertFile(key, event)
      event = deep_copy(event)
      rsa_cert = Builtins.tostring(UI.QueryWidget(Id("CertFile"), :Value))
      ssl_enable = Convert.to_boolean(UI.QueryWidget(Id("SSLEnable"), :Value))

      if (rsa_cert == "" || rsa_cert == nil) && ssl_enable
        Popup.Error(_("RSA certificate is missing."))
        UI.SetFocus(Id("CertFile"))
        return false
      end

      true
    end

    # Store function of "RSA Certificate to Use for SSL Encrypted Connections"
    # save value to temporary structure
    #
    def StoreCertFile(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "CertFile",
        Builtins.tostring(UI.QueryWidget(Id("CertFile"), :Value))
      )

      nil
    end

    # Handle function of "Browse"
    # handling value in textentry of "RSA Certificate to Use for SSL Encrypted Connections"
    def HandleBrowseCertFile(key, event)
      event = deep_copy(event)
      button = Ops.get(event, "ID")
      if button == "BrowseCertFile"
        val = UI.AskForExistingFile("/", "*.*", _("Select File"))
        UI.ChangeWidget(Id("CertFile"), :Value, val) if val
      end

      nil
    end

    # Init function of "Disable Downloading Unvalidated Data"
    # checkbox
    #
    def InitAntiWarez(key)
      UI.ChangeWidget(
        Id("AntiWarez"),
        :Value,
        FtpServer.ValueUIEdit("AntiWarez") == "YES"
      )

      nil
    end

    # Store function of "Disable Downloading Unvalidated Data"
    # save value to temporary structure
    #
    def StoreAntiWarez(key, event)
      event = deep_copy(event)
      FtpServer.WriteToEditMap(
        "AntiWarez",
        Convert.to_boolean(UI.QueryWidget(Id("AntiWarez"), :Value)) == true ? "YES" : "NO"
      )

      nil
    end

    # Init function of "Security Settings"
    # checkbox
    #
    def InitSSL(key)
      security = Builtins.tointeger(FtpServer.ValueUIEdit("SSL"))
      if security == 0
        UI.ChangeWidget(Id("SSL"), :Value, "disable")
      elsif security == 1
        UI.ChangeWidget(Id("SSL"), :Value, "accept")
      else
        UI.ChangeWidget(Id("SSL"), :Value, "refuse")
      end

      nil
    end

    # Valid function of "Security Settings"
    # check of existing certificate
    #
    def ValidSSL(key, event)
      event = deep_copy(event)
      current = Convert.to_string(UI.QueryWidget(Id("SSL"), :Value))
      if !FileUtils.Exists("/etc/ssl/private/pure-ftpd.pem") &&
          (current == "accept" || current == "refuse")
        Popup.Error(
          _(
            "The <tt>/etc/ssl/private/pure-ftpd.pem</tt> certificate for the SSL connection is missing."
          )
        )
        return false
      end
      true
    end

    # Store function of "Security Settings"
    # save value to temporary structure
    #
    def StoreSSL(key, event)
      event = deep_copy(event)
      radiobut = Convert.to_string(UI.QueryWidget(Id("SSL"), :Value))
      if radiobut == "disable"
        FtpServer.WriteToEditMap("SSL", "0")
      elsif radiobut == "accept"
        FtpServer.WriteToEditMap("SSL", "1")
      else
        FtpServer.WriteToEditMap("SSL", "2")
      end

      nil
    end
  end
end
