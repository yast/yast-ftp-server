# encoding: utf-8

# File:	include/ftpd/dialogs.ycp
# Package:	Configuration of ftpd
# Summary:	Dialogs definitions
# Authors:	Jozef Uhliarik <juhliarik@suse.cz>
#
# $Id: dialogs.ycp 27914 2006-02-13 14:32:08Z juhliarik $
module Yast
  module FtpServerDialogsInclude
    def initialize_ftp_server_dialogs(include_target)
      Yast.import "UI"

      textdomain "ftp-server"

      Yast.import "CWM"
      Yast.import "CWMServiceStart"
      Yast.import "DialogTree"
      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "FtpServer"
      Yast.import "Popup"
      Yast.import "CWMFirewallInterfaces"

      Yast.include include_target, "ftp-server/helps.rb"
      Yast.include include_target, "ftp-server/wid_functions.rb"

      # map for description of widget later in CWNTree
      # widget_descr (vsftpd)
      #
      # @return [Hash{String,map<String => Object>}]

      @wid_handling_vsftpd = {
        "StartMode"        => CWMServiceStart.CreateAutoStartWidget(StartMode()),
        "StartStop"        => CWMServiceStart.CreateStartStopWidget(StartStop()),
        "RBVsPureFTPd"     => RBVsftpdPureftpd(),
        "StartStopRestart" => StartStopRestart(),
        "Banner"           => Banner(),
        "ChrootEnable"     => ChrootEnable(),
        "VerboseLogging"   => VerboseLogging(),
        "UmaskAnon"        => UmaskAnon(),
        "UmaskLocal"       => UmaskLocal(),
        "FtpDirAnon"       => FtpDirAnon(),
        "BrowseAnon"       => BrowseAnon(),
        "FtpDirLocal"      => FtpDirLocal(),
        "BrowseLocal"      => BrowseLocal(),
        "MaxIdleTime"      => MaxIdleTime(),
        "MaxClientsPerIP"  => MaxClientsPerIP(),
        "MaxClientsNumber" => MaxClientsNumber(),
        "LocalMaxRate"     => LocalMaxRate(),
        "AnonMaxRate"      => AnonMaxRate(),
        "AnonAuthen"       => AnonAuthen(),
        "EnableUpload"     => EnableUpload(),
        "AnonReadOnly"     => AnonReadOnly(),
        "AnonCreatDirs"    => AnonCreatDirs(),
        "PassiveMode"      => PassiveMode(),
        "PasMinPort"       => PasMinPort(),
        "PasMaxPort"       => PasMaxPort(),
        "SSLEnable"        => SSLEnable(),
        "SSLv2"            => SSLv2(),
        "SSLv3"            => SSLv3(),
        "TLS"              => TLS(),
        "CertFile"         => CertFile(),
        "BrowseCertFile"   => BrowseCertFile(),
        "Firewall"         => CWMFirewallInterfaces.CreateOpenFirewallWidget(
          FirewallSettingsVs()
        )
      }


      # map for screens of widget later in CWNTree
      # screens (vsftpd)
      #
      # @return [Hash{String,map<String => Object>}]

      @tabs_vsftpd = {
        "start_up"        => start_up,
        "gen_settings"    => gen_settings,
        "perfor_settings" => perfor_settings,
        "anon_settings"   => vsftpd_anon_settings,
        "addit_settings"  => addit_settings
      }

      # function for running CWNTree
      #
      # abort functions for confirm abort
      #
      @functions = { :abort => fun_ref(method(:AbortDialog), "boolean ()") }
    end

    # Returns whether user confirmed aborting the configuration.
    #
    # @return [Boolean] result
    def AbortDialog
      if FtpServer.GetModified
        return Popup.YesNoHeadline(
          # TRANSLATORS: popup headline
          _("Aborting FTP Configuration"),
          # TRANSLATORS: popup message
          _("All changes will be lost. Really abort configuration?")
        )
      else
        return true
      end
    end

    # Init function where are added UI hadle functions
    # Start widget (vsftpd)
    #
    # @return [Hash{String => Object}] map for start-up widget


    def StartMode
      result = {}
      Ops.set(
        result,
        "get_service_auto_start",
        fun_ref(method(:GetEnableService), "boolean ()")
      )
      Ops.set(
        result,
        "set_service_auto_start",
        fun_ref(method(:SetEnableService), "void (boolean)")
      )
      Ops.set(
        result,
        "get_service_start_via_xinetd",
        fun_ref(method(:GetStartedViaXinetd), "boolean ()")
      )
      Ops.set(
        result,
        "set_service_start_via_xinetd",
        fun_ref(method(:SetStartedViaXinetd), "void (boolean)")
      )
      #TRANSLATORS: Radio selection
      Ops.set(result, "start_auto_button", _("&When booting"))
      Ops.set(result, "start_manual_button", _("&Manually"))
      Ops.set(result, "start_xinetd_button", _("Via &xinetd"))
      Ops.set(
        result,
        "help",
        Builtins.sformat(
          CWMServiceStart.AutoStartHelpXinetdTemplate,
          _("When Booting"),
          _("Manually"),
          _("Via xinetd")
        )
      )
      deep_copy(result)
    end

    # Init function where are added UI hadle functions
    # Start widget
    #
    # @return [Hash{String => Object}] map for start-stop widget

    def StartStop
      result = {}
      Ops.set(result, "service_id", "vsftpd")
      Ops.set(result, "service_running_label", _("FTP is running"))
      Ops.set(result, "service_not_running_label", _("FTP is not running"))
      Ops.set(result, "start_now_button", _("&Start FTP Now"))
      Ops.set(result, "stop_now_button", _("S&top FTP Now"))
      Ops.set(
        result,
        "save_now_action",
        fun_ref(method(:SaveAndRestartVsftpd), "boolean ()")
      )
      Ops.set(
        result,
        "save_now_button",
        _("Sa&ve Settings and Restart FTP Now")
      )
      Ops.set(
        result,
        "start_now_action",
        fun_ref(method(:StartNowVsftpd), "boolean ()")
      )
      Ops.set(
        result,
        "stop_now_action",
        fun_ref(method(:StopNowVsftpd), "boolean ()")
      )
      Ops.set(
        result,
        "help",
        Builtins.sformat(
          CWMServiceStart.StartStopHelpTemplate(true),
          # part of help text - push button label, NO SHORTCUT!!!
          _("Start FTP Daemon Now"),
          # part of help text - push button label, NO SHORTCUT!!!
          _("Stop FTP Daemon Now"),
          # part of help text - push button label, NO SHORTCUT!!!
          _("Save Settings and Restart FTP Daemon Now")
        )
      )

      deep_copy(result)
    end

    # Init function where are added UI hadle functions
    # special hack widget where is handlig Start/Stop button
    #
    # @return [Hash{String => Object}] map for start-stop widget

    def StartStopRestart
      result = {}

      Ops.set(result, "widget", :custom)
      Ops.set(result, "custom_widget", Empty())
      Ops.set(
        result,
        "init",
        fun_ref(method(:InitStartStopRestart), "void (string)")
      )
      Ops.set(result, "help", " ")



      deep_copy(result)
    end


    #-----------================= GENERAL SCREEN =============----------
    #


    # Wellcome Message for vsftpd
    # General Settings widget
    #
    # @return [Hash{String => Object}] map for General screen

    def Banner
      result = {}

      Ops.set(result, "label", _("&Welcome message"))
      Ops.set(result, "widget", :textentry)
      Ops.set(result, "opt", [:notify])
      Ops.set(result, "init", fun_ref(method(:InitBanner), "void (string)"))
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleUniversal), "symbol (string, map)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreBanner), "void (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("Banner"))

      deep_copy(result)
    end

    # Chroot Everyone
    # General Settings widget
    #
    # @return [Hash{String => Object}] map for General screen

    def ChrootEnable
      result = {}

      Ops.set(result, "label", _("&Chroot Everyone"))
      Ops.set(result, "widget", :checkbox)
      Ops.set(result, "opt", [:notify])
      Ops.set(
        result,
        "init",
        fun_ref(method(:InitChrootEnable), "void (string)")
      )
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleUniversal), "symbol (string, map)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreChrootEnable), "void (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("ChrootEnable"))

      deep_copy(result)
    end

    # Verbos Logging
    # General Settings widget
    #
    # @return [Hash{String => Object}] map for General screen

    def VerboseLogging
      result = {}

      Ops.set(result, "label", _("&Verbose Logging"))
      Ops.set(result, "widget", :checkbox)
      Ops.set(result, "opt", [:notify])
      Ops.set(
        result,
        "init",
        fun_ref(method(:InitVerboseLogging), "void (string)")
      )
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleUniversal), "symbol (string, map)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreVerboseLogging), "void (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("VerboseLogging"))

      deep_copy(result)
    end

    # Umask for Anonynous for vsftpd
    # General Settings widget
    #
    # @return [Hash{String => Object}] map for General screen


    def UmaskAnon
      result = {}

      Ops.set(result, "label", _("&Umask for Anonymous"))
      Ops.set(result, "widget", :textentry)
      Ops.set(result, "opt", [:notify])
      Ops.set(result, "init", fun_ref(method(:InitUmaskAnon), "void (string)"))
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleUniversal), "symbol (string, map)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreUmaskAnon), "void (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("UmaskAnon"))

      deep_copy(result)
    end




    # Umask for Authenticated Users for vsftpd
    # General Settings widget
    #
    # @return [Hash{String => Object}] map for General screen


    def UmaskLocal
      result = {}

      Ops.set(result, "label", _("Uma&sk for Authenticated Users"))
      Ops.set(result, "widget", :textentry)
      Ops.set(result, "opt", [:notify])
      Ops.set(result, "init", fun_ref(method(:InitUmaskLocal), "void (string)"))
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleUniversal), "symbol (string, map)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreUmaskLocal), "void (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("UmaskLocal"))

      deep_copy(result)
    end

    # Ftp Directory for Anonymous Users
    # General Settings widget
    #
    # @return [Hash{String => Object}] map for General screen


    def FtpDirAnon
      result = {}

      Ops.set(result, "label", _("FTP Directory for Anon&ymous Users"))
      Ops.set(result, "widget", :textentry)
      Ops.set(result, "opt", [:notify])
      Ops.set(result, "init", fun_ref(method(:InitFtpDirAnon), "void (string)"))
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleUniversal), "symbol (string, map)")
      )
      Ops.set(result, "validate_type", :function)
      Ops.set(
        result,
        "validate_function",
        fun_ref(method(:ValidFtpDirAnon), "boolean (string, map)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreFtpDirAnon), "void (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("FtpDirAnon"))

      deep_copy(result)
    end


    # "Browse" button for FTP Dir Anon
    # General Settings widget
    #
    # @return [Hash{String => Object}] map for General screen


    def BrowseAnon
      result = {}

      Ops.set(result, "label", _("Brows&e"))
      Ops.set(result, "widget", :push_button)
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleBrowseAnon), "symbol (string, map)")
      )
      Ops.set(result, "help", _(" "))

      deep_copy(result)
    end


    # Ftp Directory for Authenticated Users
    # General Settings widget
    #
    # @return [Hash{String => Object}] map for General screen


    def FtpDirLocal
      result = {}

      Ops.set(result, "label", _("&FTP Directory for Authenticated Users"))
      Ops.set(result, "widget", :textentry)
      Ops.set(result, "opt", [:notify])
      Ops.set(
        result,
        "init",
        fun_ref(method(:InitFtpDirLocal), "void (string)")
      )
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleUniversal), "symbol (string, map)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreFtpDirLocal), "void (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("FtpDirLocal"))

      deep_copy(result)
    end


    # "Browse" button for FTP Dir Local/Authenticated
    # General Settings widget
    #
    # @return [Hash{String => Object}] map for General screen


    def BrowseLocal
      result = {}

      Ops.set(result, "label", _("Br&owse"))
      Ops.set(result, "widget", :push_button)
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleBrowseLocal), "symbol (string, map)")
      )
      Ops.set(result, "help", _(" "))

      deep_copy(result)
    end


    #-----------================= PERFORMANCE SCREEN =============----------
    #


    # Max Idle Time [minutes]
    # Performance Settings widget
    #
    # @return [Hash{String => Object}] map for Performance screen


    def MaxIdleTime
      result = {}

      Ops.set(result, "label", _("&Max Idle Time [minutes]"))
      Ops.set(result, "widget", :intfield)
      Ops.set(result, "minimum", 0)
      Ops.set(result, "maximum", 1440)
      Ops.set(result, "opt", [:notify])
      Ops.set(
        result,
        "init",
        fun_ref(method(:InitMaxIdleTime), "void (string)")
      )
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleUniversal), "symbol (string, map)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreMaxIdleTime), "void (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("MaxIdleTime"))

      deep_copy(result)
    end



    # Max Clients for One IP
    # Performance Settings widget
    #
    # @return [Hash{String => Object}] map for Performance screen


    def MaxClientsPerIP
      result = {}

      Ops.set(result, "label", _("Max Cli&ents for One IP"))
      Ops.set(result, "widget", :intfield)
      Ops.set(result, "minimum", 0)
      Ops.set(result, "maximum", 50)
      Ops.set(result, "opt", [:notify])
      Ops.set(
        result,
        "init",
        fun_ref(method(:InitMaxClientsPerIP), "void (string)")
      )
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleUniversal), "symbol (string, map)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreMaxClientsPerIP), "void (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("MaxClientsPerIP"))

      deep_copy(result)
    end


    # Max Clients
    # Performance Settings widget
    #
    # @return [Hash{String => Object}] map for Performance screen
    def MaxClientsNumber
      result = {}

      Ops.set(result, "label", _("Ma&x Clients"))
      Ops.set(result, "widget", :intfield)
      Ops.set(result, "minimum", 0)
      Ops.set(result, "maximum", 9999)
      Ops.set(result, "opt", [:notify])
      Ops.set(
        result,
        "init",
        fun_ref(method(:InitMaxClientsNumber), "void (string)")
      )
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleUniversal), "symbol (string, map)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreMaxClientsNumber), "void (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("MaxClientsNumber"))

      deep_copy(result)
    end


    # Local Max Rate [KB/s]
    # Performance Settings widget
    #
    # @return [Hash{String => Object}] map for Performance screen
    def LocalMaxRate
      result = {}

      Ops.set(result, "label", _("&Local Max Rate [KB/s]"))
      Ops.set(result, "widget", :intfield)
      Ops.set(result, "minimum", 0)
      Ops.set(result, "maximum", 10000000)
      Ops.set(result, "opt", [:notify])
      Ops.set(
        result,
        "init",
        fun_ref(method(:InitLocalMaxRate), "void (string)")
      )
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleUniversal), "symbol (string, map)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreLocalMaxRate), "void (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("LocalMaxRate"))

      deep_copy(result)
    end


    # Anonymous Max Rate [KB/s]
    # Performance Settings widget
    #
    # @return [Hash{String => Object}] map for Performance screen
    def AnonMaxRate
      result = {}

      Ops.set(result, "label", _("Anonymous Max &Rate [KB/s]"))
      Ops.set(result, "widget", :intfield)
      Ops.set(result, "minimum", 0)
      Ops.set(result, "maximum", 10000000)
      Ops.set(result, "opt", [:notify])
      Ops.set(
        result,
        "init",
        fun_ref(method(:InitAnonMaxRate), "void (string)")
      )
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleUniversal), "symbol (string, map)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreAnonMaxRate), "void (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("AnonMaxRate"))

      deep_copy(result)
    end

    #-----------================= Authentication SCREEN =============----------
    #


    # Enable/Disable Anonymous and Local Users
    # Authentication Settings widget
    #
    # @return [Hash{String => Object}] map for Performance screen


    def AnonAuthen
      result = {}

      Ops.set(result, "label", _("Enable/Disable Anonymous and Local Users"))
      Ops.set(result, "widget", :radio_buttons)
      Ops.set(
        result,
        "items",
        [
          ["anon_only", _("Anonymo&us Only")],
          ["local_only", _("Aut&henticated Users Only")],
          ["both", _("&Both")]
        ]
      )
      Ops.set(result, "opt", [:notify])
      Ops.set(result, "init", fun_ref(method(:InitAnonAuthen), "void (string)"))
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleUniversal), "symbol (string, map)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreAnonAuthen), "void (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("AnonAuthen"))

      deep_copy(result)
    end

    # Enable Upload
    # Authentication Settings widget
    #
    # @return [Hash{String => Object}] map for Performance screen

    def EnableUpload
      result = {}

      Ops.set(result, "label", _("&Enable Upload"))
      Ops.set(result, "widget", :checkbox)
      Ops.set(
        result,
        "init",
        fun_ref(method(:InitEnableUpload), "void (string)")
      )
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleEnableUpload), "symbol (string, map)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreEnableUpload), "void (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("EnableUpload"))

      deep_copy(result)
    end


    # Anonymous Can Upload
    # Authentication Settings widget
    #
    # @return [Hash{String => Object}] map for Performance screen

    def AnonReadOnly
      result = {}

      Ops.set(result, "label", _("Anon&ymous Can Upload"))
      Ops.set(result, "widget", :checkbox)
      Ops.set(
        result,
        "init",
        fun_ref(method(:InitAnonReadOnly), "void (string)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreAnonReadOnly), "void (string, map)")
      )
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleAnonReadOnly), "symbol (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("AnonReadOnly"))

      deep_copy(result)
    end



    # Anonymous Can Create Directories
    # Authentication Settings widget
    #
    # @return [Hash{String => Object}] map for Performance screen

    def AnonCreatDirs
      result = {}

      Ops.set(result, "label", _("Anonymou&s Can Create Directories"))
      Ops.set(result, "widget", :checkbox)
      Ops.set(
        result,
        "init",
        fun_ref(method(:InitAnonCreatDirs), "void (string)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreAnonCreatDirs), "void (string, map)")
      )
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleAnonCreatDirs), "symbol (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("AnonCreatDirs"))

      deep_copy(result)
    end


    #-----------================= EXPERT SETTINGS SCREEN =============----------
    #

    # Enable Pass&ive Mode
    # Expert Settings widget
    #
    # @return [Hash{String => Object}] map for Expert screen


    def PassiveMode
      result = {}

      Ops.set(result, "label", _("Enable Pass&ive Mode"))
      Ops.set(result, "widget", :checkbox)
      Ops.set(
        result,
        "init",
        fun_ref(method(:InitPassiveMode), "void (string)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StorePassiveMode), "void (string, map)")
      )
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandlePassiveMode), "symbol (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("PassiveMode"))

      deep_copy(result)
    end



    # Min Port for Pas. Mode
    # Expert Settings widget
    #
    # @return [Hash{String => Object}] map for Expert screen
    def PasMinPort
      result = {}

      Ops.set(result, "label", _("&Min Port for Pas. Mode"))
      Ops.set(result, "widget", :intfield)
      Ops.set(result, "minimum", 1024)
      Ops.set(result, "maximum", 65535)
      Ops.set(result, "opt", [:notify])
      Ops.set(result, "init", fun_ref(method(:InitPasMinPort), "void (string)"))
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleUniversal), "symbol (string, map)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StorePasMinPort), "void (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("PasMinPort"))

      deep_copy(result)
    end



    # Max Port for Pas. Mode
    # Expert Settings widget
    #
    # @return [Hash{String => Object}] map for Expert screen


    def PasMaxPort
      result = {}

      Ops.set(result, "label", _("Max P&ort for Pas. Mode"))
      Ops.set(result, "widget", :intfield)
      Ops.set(result, "minimum", 1024)
      Ops.set(result, "maximum", 65535)
      Ops.set(result, "opt", [:notify])
      Ops.set(result, "init", fun_ref(method(:InitPasMaxPort), "void (string)"))
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleUniversal), "symbol (string, map)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StorePasMaxPort), "void (string, map)")
      )
      Ops.set(result, "validate_type", :function)
      Ops.set(
        result,
        "validate_function",
        fun_ref(method(:ValidPasMaxPort), "boolean (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("PasMaxPort"))

      deep_copy(result)
    end



    # Enable SSL
    # Expert Settings widget
    #
    # @return [Hash{String => Object}] map for Expert screen


    def SSLEnable
      result = {}

      Ops.set(result, "label", _("Enab&le SSL"))
      Ops.set(result, "widget", :checkbox)
      Ops.set(result, "init", fun_ref(method(:InitSSLEnable), "void (string)"))
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreSSLEnable), "void (string, map)")
      )
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleSSLEnable), "symbol (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("SSLEnable"))

      deep_copy(result)
    end


    # Enable SSL v2
    # Expert Settings widget
    #
    # @return [Hash{String => Object}] map for Expert screen
    def SSLv2
      result = {}

      Ops.set(result, "label", _("&Enable SSL v2"))
      Ops.set(result, "widget", :checkbox)
      Ops.set(result, "opt", [:notify])
      Ops.set(result, "init", fun_ref(method(:InitSSLv2), "void (string)"))
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleUniversal), "symbol (string, map)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreSSLv2), "void (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("SSLv2"))

      deep_copy(result)
    end


    # Enable SSL v3
    # Expert Settings widget
    #
    # @return [Hash{String => Object}] map for Expert screen


    def SSLv3
      result = {}

      Ops.set(result, "label", _("Enable SSL &v3"))
      Ops.set(result, "widget", :checkbox)
      Ops.set(result, "opt", [:notify])
      Ops.set(result, "init", fun_ref(method(:InitSSLv3), "void (string)"))
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleUniversal), "symbol (string, map)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreSSLv3), "void (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("SSLv3"))

      deep_copy(result)
    end


    # Enable TLS
    # Expert Settings widget
    #
    # @return [Hash{String => Object}] map for Expert screen


    def TLS
      result = {}

      Ops.set(result, "label", _("Enable &TLS"))
      Ops.set(result, "widget", :checkbox)
      Ops.set(result, "opt", [:notify])
      Ops.set(result, "init", fun_ref(method(:InitTLS), "void (string)"))
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleUniversal), "symbol (string, map)")
      )
      Ops.set(result, "store", fun_ref(method(:StoreTLS), "void (string, map)"))
      Ops.set(result, "help", DialogHelpText("TLS"))

      deep_copy(result)
    end


    # RSA Certificate to Use for SSL Encrypted Connections
    # Expert Settings widget
    #
    # @return [Hash{String => Object}] map for Expert screen


    def CertFile
      result = {}

      Ops.set(
        result,
        "label",
        _("D&SA Certificate to Use for SSL-encrypted Connections")
      )
      Ops.set(result, "widget", :textentry)
      Ops.set(result, "init", fun_ref(method(:InitCertFile), "void (string)"))
      Ops.set(result, "validate_type", :function)
      Ops.set(
        result,
        "validate_function",
        fun_ref(method(:ValidCertFile), "boolean (string, map)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreCertFile), "void (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("CertFile"))

      deep_copy(result)
    end


    # "Browse" button for RSA Certificate
    # Expert Settings widget
    #
    # @return [Hash{String => Object}] map for Expert screen


    def BrowseCertFile
      result = {}

      Ops.set(result, "label", _("Br&owse"))
      Ops.set(result, "widget", :push_button)
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleBrowseCertFile), "symbol (string, map)")
      )
      Ops.set(result, "help", _(" "))

      deep_copy(result)
    end




    # Disable Downloading Unvalidated Data
    # Expert Settings widget
    #
    # @return [Hash{String => Object}] map for Expert screen


    def AntiWarez
      result = {}

      Ops.set(result, "label", _("Disable Downloading &Unvalidated Data"))
      Ops.set(result, "widget", :checkbox)
      Ops.set(result, "opt", [:notify])
      Ops.set(result, "init", fun_ref(method(:InitAntiWarez), "void (string)"))
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleUniversal), "symbol (string, map)")
      )
      Ops.set(
        result,
        "store",
        fun_ref(method(:StoreAntiWarez), "void (string, map)")
      )
      Ops.set(result, "help", DialogHelpText("AntiWarez"))

      deep_copy(result)
    end


    # Security Settings
    # Expert Settings widget
    #
    # @return [Hash{String => Object}] map for Expert screen
    def SSL
      result = {}

      Ops.set(result, "label", _("Security Settings"))
      Ops.set(result, "widget", :radio_buttons)
      Ops.set(
        result,
        "items",
        [
          ["disable", _("Disable SSL/&TLS")],
          ["accept", _("Accept &SSL and TLS")],
          ["refuse", _("&Refuse Connections Without SSL/TLS")]
        ]
      )
      Ops.set(result, "opt", [:notify])
      Ops.set(result, "init", fun_ref(method(:InitSSL), "void (string)"))
      Ops.set(
        result,
        "handle",
        fun_ref(method(:HandleUniversal), "symbol (string, map)")
      )
      Ops.set(result, "validate_type", :function)
      Ops.set(
        result,
        "validate_function",
        fun_ref(method(:ValidSSL), "boolean (string, map)")
      )
      Ops.set(result, "store", fun_ref(method(:StoreSSL), "void (string, map)"))
      Ops.set(result, "help", DialogHelpText("SSL"))

      deep_copy(result)
    end

    #-----------================= SCREENS OF FTP_SERVER =============----------
    #


    # Init function where are added UI hadle functions
    # Start widget
    # define for tabs_vsftpd necessary later in screens (CWNTree)
    #
    # @return [Hash{String => Object}] map for start_up widget
    def start_up
      result = {}

      Ops.set(
        result,
        "contents",
        VBox(
          "StartMode",
          VSpacing(1),
          # disabling start/stop buttons when it doesn't make sense
          Mode.normal ? "StartStop" : Empty(),
          VStretch()
        )
      )
      # TRANSLATORS: part of dialog caption
      Ops.set(result, "caption", _("FTP Start-up"))
      # TRANSLATORS: tree menu item
      Ops.set(result, "tree_item_label", _("Start-Up"))
      Ops.set(
        result,
        "widget_names",
        ["StartMode", "StartStop", "StartStopRestart"]
      )

      deep_copy(result)
    end

    # Init function where are added UI hadle functions
    # General Settings widget (vsftpd)
    # define for tabs_vsftpd necessary later in screens (CWNTree)
    #
    # @return [Hash{String => Object}] map for General Settings widget

    def gen_settings
      result = {}

      Ops.set(
        result,
        "contents",
        VBox(
          Frame(
            _("General Settings"),
            HBox(
              HSpacing(1),
              VBox(
                Left("Banner"),
                Left("ChrootEnable"),
                Left("VerboseLogging"),
                Left(HBox(Left("UmaskAnon"), Left("UmaskLocal")))
              )
            )
          ),
          VSpacing(1),
          Frame(
            _("FTP Directories"),
            HBox(
              HSpacing(1),
              VBox(
                Left(
                  HBox(
                    HSpacing(1),
                    Left("FtpDirAnon"),
                    VBox(Left(Label("")), Left("BrowseAnon"))
                  )
                ),
                Left(
                  HBox(
                    HSpacing(1),
                    Left("FtpDirLocal"),
                    VBox(Left(Label("")), Left("BrowseLocal"))
                  )
                )
              )
            )
          ),
          VStretch()
        )
      )
      # TRANSLATORS: part of dialog caption
      Ops.set(result, "caption", _("FTP General Settings"))
      # TRANSLATORS: tree menu item
      Ops.set(result, "tree_item_label", _("General"))
      Ops.set(
        result,
        "widget_names",
        [
          "Banner",
          "ChrootEnable",
          "VerboseLogging",
          "UmaskAnon",
          "UmaskLocal",
          "BrowseAnon",
          "BrowseLocal",
          "FtpDirAnon",
          "FtpDirLocal"
        ]
      )

      deep_copy(result)
    end

    # Init function where are added UI hadle functions
    # Performance Settings widget
    # define for tabs_vsftpd necessary later in screens (CWNTree)
    #
    # @return [Hash{String => Object}] map for Performance Settings widget


    def perfor_settings
      result = {}

      Ops.set(
        result,
        "contents",
        VBox(
          Frame(
            _("General Settings"),
            HBox(
              HSpacing(1),
              VBox(
                Left(MinWidth(20, "MaxIdleTime")),
                Left(MinWidth(20, "MaxClientsPerIP")),
                Left(MinWidth(20, "MaxClientsNumber"))
              )
            )
          ),
          VSpacing(1),
          Frame(
            _("FTP Directories"),
            HBox(
              HSpacing(1),
              VBox(
                Left(MinWidth(20, "LocalMaxRate")),
                Left(MinWidth(20, "AnonMaxRate"))
              )
            )
          ),
          VStretch()
        )
      )
      # TRANSLATORS: part of dialog caption
      Ops.set(result, "caption", _("FTP Performance Settings"))
      # TRANSLATORS: tree menu item
      Ops.set(result, "tree_item_label", _("Performance"))
      Ops.set(
        result,
        "widget_names",
        [
          "MaxClientsPerIP",
          "MaxIdleTime",
          "AnonMaxRate",
          "LocalMaxRate",
          "MaxClientsNumber"
        ]
      )

      deep_copy(result)
    end

    # Init function where are added firewall
    #
    # @return [Hash{String => Object}] map for firewall settings
    def FirewallSettingsVs
      {
        "services"        => ["vsftpd"],
        "display_details" => true
      }
    end


    # Init function where are added UI hadle functions
    # Anonymous Settings widget
    # define for tabs_vsftpd necessary later in screens (CWNTree)
    #
    # @return [Hash{String => Object}] map for Anonymous Settings widget

    def anon_settings
      result = {}

      Ops.set(
        result,
        "contents",
        VBox(
          "AnonAuthen",
          VSpacing(1),
          Frame(
            _("Uploading"),
            HBox(HSpacing(1), VBox(Left("AnonReadOnly"), Left("AnonCreatDirs")))
          ),
          VStretch()
        )
      )
      # TRANSLATORS: part of dialog caption
      Ops.set(result, "caption", _("FTP Anonymous Settings"))
      # TRANSLATORS: tree menu item
      Ops.set(result, "tree_item_label", _("Authentication"))
      Ops.set(
        result,
        "widget_names",
        ["AnonAuthen", "AnonReadOnly", "AnonCreatDirs"]
      )

      deep_copy(result)
    end

    # Init function where are added UI hadle functions
    # Anonymous Settings widget
    # define for tabs_vsftpd necessary later in screens (CWNTree)
    #
    # @return [Hash{String => Object}] map for Anonymous Settings widget

    def vsftpd_anon_settings
      result = {}

      Ops.set(
        result,
        "contents",
        VBox(
          "AnonAuthen",
          VSpacing(1),
          Frame(
            _("Uploading"),
            HBox(
              HSpacing(1),
              VBox(
                Left("EnableUpload"),
                HBox(
                  HSpacing(2),
                  VBox(Left("AnonReadOnly"), Left("AnonCreatDirs"))
                )
              )
            )
          ),
          VStretch()
        )
      )
      # TRANSLATORS: part of dialog caption
      Ops.set(result, "caption", _("FTP Anonymous Settings"))
      # TRANSLATORS: tree menu item
      Ops.set(result, "tree_item_label", _("Authentication"))
      Ops.set(
        result,
        "widget_names",
        ["AnonAuthen", "EnableUpload", "AnonReadOnly", "AnonCreatDirs"]
      )

      deep_copy(result)
    end
    # Init function where are added UI hadle functions
    # Expert Settings widget (vsftpd)
    # define for tabs_vsftpd necessary later in screens (CWNTree)
    #
    # @return [Hash{String => Object}] map for Expert Settings widget

    def addit_settings
      result = {}

      Ops.set(
        result,
        "contents",
        VBox(
          Frame(
            _("Passive Mode"),
            HBox(
              HSpacing(1),
              VBox(
                Left("PassiveMode"),
                HBox(
                  HSpacing(2),
                  Left(HSquash(HBox("PasMinPort", "PasMaxPort", HStretch())))
                )
              )
            )
          ), #end of `Frame ( "Passiv Mode Settings"
          VSpacing(1),
          Frame(
            _("Enab&le SSL"), # end of `HBox(`HSpacing(1),`VBox (
            #`CheckBoxFrame(`id("SSLEnable"), _("Enab&le SSL"), true,
            HBox(
              HSpacing(1),
              VBox(
                Left("SSLEnable"), # end of `HBox(`HSpacing(1),`VBox (
                HBox(
                  HSpacing(2),
                  VBox(
                    Left("SSLv2"), # end of `Left(`HBox(
                    Left("SSLv3"),
                    Left("TLS"),
                    Left(HBox("CertFile", VBox(Label(""), "BrowseCertFile")))
                  )
                )
              )
            )
          ), #end of `CheckBoxFrame(`id("SSLEnable"), "Sec&urity Settings", true
          VSpacing(1),
          Frame(_("SUSEfirewall Settings"), HBox(HSpacing(1), "Firewall")),
          VStretch()
        )
      )
      # TRANSLATORS: part of dialog caption
      Ops.set(result, "caption", _("FTP Expert Settings"))
      # TRANSLATORS: tree menu item
      Ops.set(result, "tree_item_label", _("Expert Settings"))
      Ops.set(
        result,
        "widget_names",
        [
          "Firewall",
          "PasMinPort",
          "PasMaxPort",
          "SSLv2",
          "SSLv3",
          "TLS",
          "CertFile",
          "BrowseCertFile",
          "PassiveMode",
          "SSLEnable"
        ]
      )

      deep_copy(result)
    end

    # function for running CWNTree
    # vsftpd
    #
    # @return [Symbol] return value of DialogTree::ShowAndRun
    def RunFTPDialogsVsftpd
      sim_dialogs = [
        "start_up",
        "gen_settings",
        "perfor_settings",
        "anon_settings",
        "addit_settings"
      ]

      DialogTree.ShowAndRun(
        {
          "ids_order"      => sim_dialogs,
          "initial_screen" => "start_up",
          "screens"        => @tabs_vsftpd,
          "widget_descr"   => @wid_handling_vsftpd,
          "back_button"    => "",
          "abort_button"   => Label.CancelButton,
          "next_button"    => Label.FinishButton,
          "functions"      => @functions
        }
      )
    end
  end
end
