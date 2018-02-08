# encoding: utf-8

# File:	include/ftp-server/wid_functions.ycp
# Package:	Configuration of ftp-server
# Summary:	Wizards definitions
# Authors:	Jozef Uhliarik <juhliarik@suse.cz>
#
# $Id: wid_functions.ycp 27914 2006-02-13 14:32:08Z juhliarik $
module Yast
  module FtpServerWidFunctionsInclude
    include Yast::Logger

    def initialize_ftp_server_wid_functions(_include_target)
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

    # CWMServiceStart function with one boolean parameter
    # returning boolean value that says if the service will be started at boot.
    def SetStartedViaXinetd(enable_service)
      FtpServer.EDIT_SETTINGS["StartDaemon"] = enable_service ? "2" : "0"

      nil
    end


    def UpdateInfoAboutStartingFTP
      #which radiobutton is selected for starting "when booting", "via socket" or "manually"
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

      UpdateInfoAboutStartingFTP()

      if Ops.get(FtpServer.EDIT_SETTINGS, "StartDaemon") == "2"
        SCR.Write(Builtins.add(path(".vsftpd"), "listen"), nil)
        SCR.Write(Builtins.add(path(".vsftpd"), "listen_ipv6"), nil)
        SCR.Write(path(".vsftpd"), nil)

        FtpServer.WriteStartViaSocket(true)
      else
        SCR.Write(Builtins.add(path(".vsftpd"), "listen"), "YES")
        SCR.Write(Builtins.add(path(".vsftpd"), "listen_ipv6"), nil)
        SCR.Write(path(".vsftpd"), nil)
        Service.enable("vsftpd")
        Service.start("vsftpd")
      end
      InitStartStopRestart()
      true
    end


    # Function stop vsftpd
    def StopNowVsftpd
      if FtpServer.start_via_socket?
        # if socket is listening, stop it
        FtpServer.WriteStartViaSocket(false)
      end
      Service.stop("vsftpd")

      InitStartStopRestart()
      true
    end

    # Function saves configuration and restarts vsftpd
    def SaveAndRestartVsftpd
      StopNowVsftpd()
      FtpServer.WriteSettings
      result = StartNowVsftpd()
      FtpServer.WriteUpload
      result
    end

    # Init function for start-up
    #
    # init starting via socket and update status
    def InitStartStopRestart(_key = nil)
      log.info "current status socket: #{FtpServer.start_via_socket?} service: #{Service.active?("vsftpd")}"
      if FtpServer.start_via_socket? || Service.active?("vsftpd")
        UI.ReplaceWidget(
          Id("_cwm_service_status_rp"),
          Label(_("FTP is running"))
        )
        UI.ChangeWidget(Id("_cwm_start_service_now"), :Enabled, false)
        UI.ChangeWidget(Id("_cwm_stop_service_now"), :Enabled, true)
      else
        UI.ReplaceWidget(
          Id("_cwm_service_status_rp"),
          Label(_("FTP is not running"))
        )
        UI.ChangeWidget(Id("_cwm_start_service_now"), :Enabled, true)
        UI.ChangeWidget(Id("_cwm_stop_service_now"), :Enabled, false)
      end

      nil
    end

    #-----------================= GENERAL SCREEN =============----------
    #

    # Init function "Wellcome Message" for general settings
    # change ValidChars for textentry
    # only vsftpd
    def InitBanner(_key)
      UI.ChangeWidget(Id("Banner"), :Value, FtpServer.ValueUIEdit("Banner"))

      nil
    end

    # Handle function only save info about changes
    def HandleUniversal(_key, event)
      # modified
      if Ops.get_string(event, "EventReason", "") == "ValueChanged"
        FtpServer.SetModified(true)
      end
      nil
    end

    # Store function of "Wellcome Message"
    # save values to temporary structure
    # only vsftpd
    def StoreBanner(_key, _event)
      FtpServer.WriteToEditMap(
        "Banner",
        Builtins.tostring(UI.QueryWidget(Id("Banner"), :Value))
      )

      nil
    end

    # Init function "Chroot Everyone" for general settings
    # check_box
    def InitChrootEnable(_key)
      UI.ChangeWidget(
        Id("ChrootEnable"),
        :Value,
        FtpServer.ValueUIEdit("ChrootEnable") == "YES"
      )

      nil
    end

    # Store function of "Chroot Everyone"
    # save values to temporary structure
    def StoreChrootEnable(_key, _event)
      FtpServer.WriteToEditMap(
        "ChrootEnable",
        Convert.to_boolean(UI.QueryWidget(Id("ChrootEnable"), :Value)) == true ? "YES" : "NO"
      )

      nil
    end

    # Init function "Verbose Logging" for general settings
    # check_box
    def InitVerboseLogging(_key)
      UI.ChangeWidget(
        Id("VerboseLogging"),
        :Value,
        FtpServer.ValueUIEdit("VerboseLogging") == "YES"
      )

      nil
    end

    # Store function of "Verbose Logging"
    # save values to temporary structure
    def StoreVerboseLogging(_key, _event)
      FtpServer.WriteToEditMap(
        "VerboseLogging",
        Convert.to_boolean(UI.QueryWidget(Id("VerboseLogging"), :Value)) == true ? "YES" : "NO"
      )

      nil
    end

    # Init function "Umask for Anonymous" for general settings
    # change ValidChars for textentry
    # only vsftpd
    def InitUmaskAnon(_key)
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
    def StoreUmaskAnon(_key, _event)
      FtpServer.WriteToEditMap(
        "UmaskAnon",
        Builtins.tostring(UI.QueryWidget(Id("UmaskAnon"), :Value))
      )

      nil
    end


    # Init function "Umask for Authenticated Users" for general settings
    # change ValidChars for textentry
    # only vsftpd
    def InitUmaskLocal(_key)
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
    def StoreUmaskLocal(_key, _event)
      FtpServer.WriteToEditMap(
        "UmaskLocal",
        Builtins.tostring(UI.QueryWidget(Id("UmaskLocal"), :Value))
      )

      nil
    end

    # Init function of "Ftp Directory for Anonymous Users"
    # textentry
    #
    def InitFtpDirAnon(_key)
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
    def ValidFtpDirAnon(_key, _event)
      true
    end

    # Store function of "Ftp Directory for Anon&ymous Users"
    # save values to temporary structure
    #
    def StoreFtpDirAnon(_key, _event)
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
    def HandleBrowseAnon(_key, event)
      button = Ops.get(event, "ID")
      if button == "BrowseAnon"
        val = UI.AskForExistingDirectory("/", _("Select directory"))
        UI.ChangeWidget(Id("FtpDirAnon"), :Value, val)
      end
      nil
    end

    # Init function of "Ftp Directory for Authenticated Users"
    # textentry
    #
    def InitFtpDirLocal(_key)
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
    def StoreFtpDirLocal(_key, _event)
      FtpServer.WriteToEditMap(
        "FtpDirLocal",
        Builtins.tostring(UI.QueryWidget(Id("FtpDirLocal"), :Value))
      )

      nil
    end

    # Handle function of "Browse"
    # handling value in textentry of "Umask for Authenticated Users"
    def HandleBrowseLocal(_key, event)
      button = Ops.get(event, "ID")
      if button == "BrowseLocal"
        val = UI.AskForExistingDirectory("/", _("Select directory"))
        UI.ChangeWidget(Id("FtpDirLocal"), :Value, val)
      end
      nil
    end


    #-----------================= PERFORMANCE SCREEN =============----------
    #

    # Init function of "Max Idle Time [minutes]"
    # intfield
    #
    def InitMaxIdleTime(_key)
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
    def StoreMaxIdleTime(_key, _event)
      FtpServer.WriteToEditMap(
        "MaxIdleTime",
        Builtins.tostring(UI.QueryWidget(Id("MaxIdleTime"), :Value))
      )

      nil
    end


    # Init function of "Max Clients for One IP"
    # intfield
    #
    def InitMaxClientsPerIP(_key)
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
    def StoreMaxClientsPerIP(_key, _event)
      FtpServer.WriteToEditMap(
        "MaxClientsPerIP",
        Builtins.tostring(UI.QueryWidget(Id("MaxClientsPerIP"), :Value))
      )

      nil
    end


    # Init function of "Max Clients"
    # intfield
    #
    def InitMaxClientsNumber(_key)
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
    def StoreMaxClientsNumber(_key, _event)
      FtpServer.WriteToEditMap(
        "MaxClientsNumber",
        Builtins.tostring(UI.QueryWidget(Id("MaxClientsNumber"), :Value))
      )

      nil
    end


    # Init function of "Local Max Rate [KB/s]"
    # intfield
    #
    def InitLocalMaxRate(_key)
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
    def StoreLocalMaxRate(_key, _event)
      FtpServer.WriteToEditMap(
        "LocalMaxRate",
        Builtins.tostring(UI.QueryWidget(Id("LocalMaxRate"), :Value))
      )

      nil
    end

    # Init function of "Anonymous Max Rate [KB/s]"
    # intfield
    #
    def InitAnonMaxRate(_key)
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
    def StoreAnonMaxRate(_key, _event)
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
    def InitAnonAuthen(_key)
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
    def StoreAnonAuthen(_key, _event)
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
    def InitEnableUpload(_key)
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
    def HandleEnableUpload(_key, event)
      button = Ops.get(event, "ID")
      #Popup::Message("Hello world");
      if Mode.normal
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
    def StoreEnableUpload(_key, _event)
      FtpServer.WriteToEditMap(
        "EnableUpload",
        Convert.to_boolean(UI.QueryWidget(Id("EnableUpload"), :Value)) == true ? "YES" : "NO"
      )

      nil
    end



    # Init function of "Anonymous Can Upload"
    # checkbox
    #
    def InitAnonReadOnly(_key)
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
    def HandleAnonReadOnly(_key, event)
      enable = Convert.to_boolean(UI.QueryWidget(Id("AnonReadOnly"), :Value))

      if enable
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
        end
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
    def StoreAnonReadOnly(_key, _event)
      FtpServer.WriteToEditMap(
        "AnonReadOnly",
        Convert.to_boolean(UI.QueryWidget(Id("AnonReadOnly"), :Value)) == true ? "NO" : "YES"
      )

      nil
    end

    # Init function of "Anonymous Can Create Directories"
    # checkbox
    #
    def InitAnonCreatDirs(_key)
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
    def HandleAnonCreatDirs(_key, event)
      enable = Convert.to_boolean(UI.QueryWidget(Id("AnonReadOnly"), :Value))

      if enable
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
        end
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
    def StoreAnonCreatDirs(_key, _event)
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
    def InitPassiveMode(_key)
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
    def HandlePassiveMode(_key, event)
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
    def StorePassiveMode(_key, _event)
      FtpServer.WriteToEditMap(
        "PassiveMode",
        Convert.to_boolean(UI.QueryWidget(Id("PassiveMode"), :Value)) == true ? "YES" : "NO"
      )

      nil
    end

    # Init function of "Min Port for Pas. Mode"
    # intfield
    #
    def InitPasMinPort(_key)
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
    def StorePasMinPort(_key, _event)
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
    def InitPasMaxPort(_key)
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
    def ValidPasMaxPort(_key, _event)
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
    def StorePasMaxPort(_key, _event)
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
    def InitSSLEnable(_key)
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
    def HandleSSLEnable(_key, event)
      event = deep_copy(event)
      value = Convert.to_boolean(UI.QueryWidget(Id("SSLEnable"), :Value))
      if value
        UI.ChangeWidget(Id("SSLv2"), :Enabled, true)
        UI.ChangeWidget(Id("SSLv3"), :Enabled, true)
        UI.ChangeWidget(Id("TLS"), :Enabled, true)
        UI.ChangeWidget(Id("CertFile"), :Enabled, true)
        UI.ChangeWidget(Id("BrowseCertFile"), :Enabled, true)
      else
        UI.ChangeWidget(Id("SSLv2"), :Enabled, false)
        UI.ChangeWidget(Id("SSLv3"), :Enabled, false)
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
    def StoreSSLEnable(_key, _event)
      FtpServer.WriteToEditMap(
        "SSLEnable",
        Convert.to_boolean(UI.QueryWidget(Id("SSLEnable"), :Value)) == true ? "YES" : "NO"
      )

      nil
    end

    # Init function of "Enable SSL v2"
    # intfield
    #
    # also include handling enable/disable SSL
    # handling checkboxframe
    def InitSSLv2(_key)
      UI.ChangeWidget(
        Id("SSLv2"),
        :Value,
        FtpServer.ValueUIEdit("SSLv2") == "YES"
      )
      UI.ChangeWidget(
        Id("SSLEnable"),
        :Value,
        FtpServer.ValueUIEdit("SSLEnable") == "YES"
      )

      nil
    end

    # Store function of "Enable SSL v2"
    # save values to temporary structure
    #
    # also include handling value enable/disable passive mode
    def StoreSSLv2(_key, _event)
      FtpServer.WriteToEditMap(
        "SSLv2",
        Convert.to_boolean(UI.QueryWidget(Id("SSLv2"), :Value)) == true ? "YES" : "NO"
      )
      FtpServer.WriteToEditMap(
        "SSLEnable",
        Convert.to_boolean(UI.QueryWidget(Id("SSLEnable"), :Value)) == true ? "YES" : "NO"
      )

      nil
    end

    # Init function of "Enable SSL v3"
    # intfield
    #
    def InitSSLv3(_key)
      UI.ChangeWidget(
        Id("SSLv3"),
        :Value,
        FtpServer.ValueUIEdit("SSLv3") == "YES"
      )

      nil
    end

    # Store function of "Enable SSL v3"
    # save value to temporary structure
    #
    def StoreSSLv3(_key, _event)
      FtpServer.WriteToEditMap(
        "SSLv3",
        Convert.to_boolean(UI.QueryWidget(Id("SSLv3"), :Value)) == true ? "YES" : "NO"
      )

      nil
    end

    # Init function of "Enable TLS"
    # intfield
    #
    def InitTLS(_key)
      UI.ChangeWidget(Id("TLS"), :Value, FtpServer.ValueUIEdit("TLS") == "YES")

      nil
    end

    # Store function of "Enable TLS"
    # save value to temporary structure
    #
    def StoreTLS(_key, _event)
      FtpServer.WriteToEditMap(
        "TLS",
        Convert.to_boolean(UI.QueryWidget(Id("TLS"), :Value)) == true ? "YES" : "NO"
      )

      nil
    end

    # Init function of "RSA Certificate to Use for SSL Encrypted Connections"
    # intfield
    #
    def InitCertFile(_key)
      UI.ChangeWidget(Id("CertFile"), :Value, FtpServer.ValueUIEdit("CertFile"))

      nil
    end

    # Valid function of "RSA Certificate to Use for SSL Encrypted Connections"
    # check value if user enable SSL Certificate (textentry) doesn't be empty
    #
    def ValidCertFile(_key, _event)
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
    def StoreCertFile(_key, _event)
      FtpServer.WriteToEditMap(
        "CertFile",
        Builtins.tostring(UI.QueryWidget(Id("CertFile"), :Value))
      )

      nil
    end

    # Handle function of "Browse"
    # handling value in textentry of "RSA Certificate to Use for SSL Encrypted Connections"
    def HandleBrowseCertFile(_key, event)
      event = deep_copy(event)
      button = Ops.get(event, "ID")
      if button == "BrowseCertFile"
        val = UI.AskForExistingFile("/", "*.*", _("Select File"))
        UI.ChangeWidget(Id("CertFile"), :Value, val)
      end

      nil
    end

    # Init function of "Disable Downloading Unvalidated Data"
    # checkbox
    #
    def InitAntiWarez(_key)
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
    def StoreAntiWarez(_key, _event)
      FtpServer.WriteToEditMap(
        "AntiWarez",
        Convert.to_boolean(UI.QueryWidget(Id("AntiWarez"), :Value)) == true ? "YES" : "NO"
      )

      nil
    end

    # Init function of "Security Settings"
    # checkbox
    #
    def InitSSL(_key)
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
    def ValidSSL(_key, _event)
      true
    end

    # Store function of "Security Settings"
    # save value to temporary structure
    #
    def StoreSSL(_key, _event)
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
