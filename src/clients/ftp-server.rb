# encoding: utf-8

# File:	clients/ftp-server.ycp
# Package:	Configuration of ftp-server
# Summary:	Main file
# Authors:	Jozef Uhliarik <juhliarik@suse.cz>
#
# $Id: ftp-server.ycp 27914 2006-02-13 14:32:08Z juhliarik $
#
# Main file for ftp-server configuration. Uses all other files.
module Yast
  class FtpServerClient < Client
    def main
      Yast.import "UI"

      # **
      # <h3>Configuration of ftp-server</h3>

      textdomain "ftp-server"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("[ftp-server] module started")

      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Summary"
      Yast.import "String"

      Yast.include self, "ftp-server/complex.rb"

      # if (!ReadFTPService ())
      #   return nil;

      Yast.import "CommandLine"
      Yast.include self, "ftp-server/wizards.rb"
      Yast.include self, "ftp-server/wid_functions.rb"

      @cmdline_description = {
        "id"         => "ftp-server",
        # Command line help text for the Xftpd module
        "help"       => _(
          "Configuration of FTP server"
        ),
        "guihandler" => fun_ref(method(:FtpdSequence), "any ()"),
        "initialize" => fun_ref(FtpServer.method(:Read), "boolean ()"),
        "finish"     => fun_ref(FtpServer.method(:Write), "boolean ()"),
        "actions"    => {
          "show"            => {
            "handler" => fun_ref(method(:FTPdCMDShow), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _("Display settings"),
            "example" => ["show"]
          },
          "startup"         => {
            "handler" => fun_ref(method(:FTPdCMDStartup), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _("Start-up settings"),
            "example" => [
              "startup atboot",
              "startup manual",
              "startup socket"
            ]
          },
          "chroot"          => {
            "handler" => fun_ref(method(:FTPdCMDChrooting), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _(
              "Enable/disable chrooting."
            ),
            "example" => ["chroot enable", "chroot disable"]
          },
          "logging"         => {
            "handler" => fun_ref(method(:FTPdCMDLogging), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _(
              "Saved log messages into the log file."
            ),
            "example" => ["logging enable", "logging disable"]
          },
          "umask"           => {
            "handler" => fun_ref(method(:FTPdCMDUmask), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _(
              "Umask <local users>:<anonymous>"
            ),
            "example" => ["umask set_umask=177:077"]
          },
          "anon_dir"        => {
            "handler" => fun_ref(method(:FTPdCMDAnonDir), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _(
              "Enter the existing directory for anonymous users."
            ),
            "example" => ["anon_dir set_anon_dir=/srv/ftp"]
          },
          "port_range"      => {
            "handler" => fun_ref(method(:FTPdCMDPassPorts), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _(
              "The port range for passive connection replies"
            ),
            "example" => ["port_range set_min_port=20000 set_max_port=30000"]
          },
          "idle_time"       => {
            "handler" => fun_ref(method(:FTPdCMDIdleTime), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _(
              "The maximum idle time in minutes"
            ),
            "example" => ["idle_time set_idle_time=15"]
          },
          "max_clients_ip"  => {
            "handler" => fun_ref(method(:FTPdCMDMaxClientsIP), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _(
              "The maximum number of clients connected via IP"
            ),
            "example" => ["max_clients_ip set_max_clients=20"]
          },
          "max_clients"     => {
            "handler" => fun_ref(method(:FTPdCMDMaxClients), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _(
              "The maximum connected clients"
            ),
            "example" => ["max_clients set_max_clients=1500"]
          },
          "max_rate_authen" => {
            "handler" => fun_ref(method(:FTPdCMDMaxRateAuthen), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _(
              "The maximum data transfer rate permitted for local authenticated users (KB/s)"
            ),
            "example" => ["max_rate_authen set_max_rate=10000"]
          },
          "max_rate_anon"   => {
            "handler" => fun_ref(method(:FTPdCMDMaxRateAnon), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _(
              "The maximum data transfer rate permitted for anonymous clients (KB/s)"
            ),
            "example" => ["max_rate_anon set_max_rate=10000"]
          },
          "access"          => {
            "handler" => fun_ref(method(:FTPdCMDAccess), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _("Access permissions"),
            "example" => [
              "access anon_only",
              "access authen_only",
              "access anon_and_authen"
            ]
          },
          "anon_access"     => {
            "handler" => fun_ref(method(:FTPdCMDAnonAccess), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _(
              "Access permissions for anonymous users"
            ),
            "example" => [
              "access anon_only",
              "access authen_only",
              "access anon_and_authen"
            ]
          },
          "welcome_message" => {
            "handler" => fun_ref(method(:FTPdCMDWelMessage), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _(
              "Welcome message is the text to display when someone connects to the server (vsftpd only)."
            ),
            "example" => ["welcome_message=\"hello everybody\""]
          },
          "SSL"             => {
            "handler" => fun_ref(method(:FTPdCMDSSL), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _(
              "vsftpd supports secure connections via SSL (vsftpd only)."
            ),
            "example" => ["SSL enable", "SSL disable"]
          },
          "TLS"             => {
            "handler" => fun_ref(method(:FTPdCMDTLS), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _(
              "Allow connections via TLS."
            ),
            "example" => ["TLS enable", "TLS disable"]
          }
        },
        "options"    => {
          "atboot"          => {
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Start FTP daemon in the boot process."
            )
          },
          "socket"          => {
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Start FTP daemon via systemd socket."
            )
          },
          "manual"          => {
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Start FTP daemon manually."
            )
          },
          "enable"          => {
            # TRANSLATORS: CommandLine help
            "help" => _("Enable option")
          },
          "disable"         => {
            # TRANSLATORS: CommandLine help
            "help" => _("Disable option")
          },
          "set_umask"       => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _("Disable option")
          },
          "set_anon_dir"    => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Directory for anonymous users"
            )
          },
          "set_min_port"    => {
            "type" => "integer",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "The minimum value for port range for passive connection replies"
            )
          },
          "set_max_port"    => {
            "type" => "integer",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "The maximum value for port range for passive connection replies"
            )
          },
          "set_idle_time"   => {
            "type" => "integer",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Maximum Idle Time (in minutes)"
            )
          },
          "set_max_clients" => {
            "type" => "integer",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "The maximum connected clients"
            )
          },
          "set_max_rate"    => {
            "type" => "integer",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "The maximum data transfer rate for ftp users (KB/s)"
            )
          },
          "anon_only"       => {
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Access only for anonymous"
            )
          },
          "authen_only"     => {
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Access only for authenticated users"
            )
          },
          "anon_and_authen" => {
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Access for anonymous and authenticated users"
            )
          },
          "can_upload"      => {
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Anonymous users can upload."
            )
          },
          "create_dirs"     => {
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Anonymous users can create directories."
            )
          },
          # only vsftd
          "set_message"     => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Welcome message is the text to display when someone connects to the server."
            )
          },
          # only vsftd
          "SSL2"            => {
            # TRANSLATORS: CommandLine help
            "help" => _("SSL version 2")
          },
          # only vsftd
          "SSL3"            => {
            # TRANSLATORS: CommandLine help
            "help" => _("SSL version 3")
          },
          # only vsftd
          "only"            => {
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Refuse connections that do not use SSL/TLS security mechanisms."
            )
          }
        },
        "mappings"   => {
          "show"            => [],
          "startup"         => ["atboot", "manual", "socket"],
          "logging"         => ["enable", "disable"],
          "chroot"          => ["enable", "disable"],
          "umask"           => ["set_umask"],
          "anon_dir"        => ["set_anon_dir"],
          "port_range"      => ["set_min_port", "set_max_port"],
          "idle_time"       => ["set_idle_time"],
          "max_clients_ip"  => ["set_max_clients"],
          "max_clients"     => ["set_max_clients"],
          "max_rate_authen" => ["set_max_rate"],
          "max_rate_anon"   => ["set_max_rate"],
          "access"          => ["anon_only", "authen_only", "anon_and_authen"],
          "anon_access"     => ["can_upload", "create_dirs"],
          "welcome_message" => ["set_message"],
          "SSL"             => ["enable", "disable"],
          "TLS"             => ["enable", "disable"]
        }
      }

      # is this proposal or not?
      @propose = false
      @args = WFM.Args
      if Ops.greater_than(Builtins.size(@args), 0)
        if Ops.is_path?(WFM.Args(0)) && WFM.Args(0) == path(".propose")
          Builtins.y2milestone("[ftp-server] Using PROPOSE mode")
          @propose = true
        end
      end

      # main ui function
      @ret = nil

      @ret = if @propose
        FtpServerAutoSequence()
      else
        CommandLine.Run(@cmdline_description)
      end

      Builtins.y2debug("ret=%1", @ret)

      # Finish
      Builtins.y2milestone("[ftp-server] module finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret)

      # EOF
    end

    def FTPdCMDShow(_options)
      CommandLine.Print("")
      CommandLine.Print(String.UnderlinedHeader(_("Display Settings:"), 0))
      CommandLine.Print("")
      # start-up settings
      CommandLine.PrintNoCR(_("Start-Up:"))
      if started_via_socket?
        CommandLine.Print(_("FTP daemon is started via socket."))
      else
        if GetEnableService()
          # TRANSLATORS: CommandLine informative text
          CommandLine.Print(_("FTP daemon is enabled in the boot process."))
        else
          # TRANSLATORS: CommandLine informative text
          CommandLine.Print(_("FTP daemon needs manual starting."))
        end
      end
      # logging settings
      CommandLine.PrintNoCR(_("Verbose Logging:"))
      if Ops.get(FtpServer.EDIT_SETTINGS, "VerboseLogging") == "YES"
        CommandLine.Print(_("Enable"))
        # CommandLine::Print("");
      else
        CommandLine.Print(_("Disable"))
        # CommandLine::Print("");
      end
      # chroot settings
      CommandLine.PrintNoCR(_("Chroot Everyone:"))
      if Ops.get(FtpServer.EDIT_SETTINGS, "ChrootEnable") == "YES"
        CommandLine.Print(_("Enable"))
        # CommandLine::Print("");
      else
        CommandLine.Print(_("Disable"))
        # CommandLine::Print("");
      end

      # UMASK settings
      if Ops.get(FtpServer.EDIT_SETTINGS, "UmaskAnon") != ""
        CommandLine.PrintNoCR(_("Umask for Anonymous: "))
        CommandLine.Print(Ops.get(FtpServer.EDIT_SETTINGS, "UmaskAnon"))
      else
        CommandLine.PrintNoCR(_("Umask for Anonymous:"))
        CommandLine.Print(_("Option is not set now."))
      end
      if Ops.get(FtpServer.EDIT_SETTINGS, "UmaskLocal") != ""
        CommandLine.PrintNoCR(_("Umask for Authenticated Users: "))
        CommandLine.Print(Ops.get(FtpServer.EDIT_SETTINGS, "UmaskLocal"))
        # CommandLine::Print("");
      else
        CommandLine.PrintNoCR(_("Umask for Authenticated Users: "))
        CommandLine.Print(_("Option is not set now."))
        # CommandLine::Print("");
      end

      # authenticated and anonymous dirs
      CommandLine.PrintNoCR(_("Authenticated dir: "))
      if Ops.get(FtpServer.EDIT_SETTINGS, "FtpDirLocal") != ""
        CommandLine.Print(Ops.get(FtpServer.EDIT_SETTINGS, "FtpDirLocal"))
      else
        CommandLine.Print(_("Option is not set now."))
      end

      CommandLine.PrintNoCR(_("Anonymous dir: "))
      if Ops.get(FtpServer.EDIT_SETTINGS, "FtpDirAnon") != ""
        CommandLine.Print(Ops.get(FtpServer.EDIT_SETTINGS, "FtpDirAnon"))
      else
        CommandLine.Print(_("Option is not set now."))
      end
      # port range
      CommandLine.PrintNoCR(_("Port Range: "))
      if Ops.get(FtpServer.EDIT_SETTINGS, "PasMaxPort") != "0"
        CommandLine.PrintNoCR(Ops.get(FtpServer.EDIT_SETTINGS, "PasMinPort"))
        CommandLine.PrintNoCR(_(" - "))
        CommandLine.Print(Ops.get(FtpServer.EDIT_SETTINGS, "PasMaxPort"))
      else
        CommandLine.Print(_("Option is not set now."))
      end

      # idle time
      CommandLine.PrintNoCR(_("Maximum Idle Time [minutes]: "))
      if Ops.get(FtpServer.EDIT_SETTINGS, "MaxIdleTime") != "0"
        CommandLine.Print(Ops.get(FtpServer.EDIT_SETTINGS, "MaxIdleTime"))
      else
        CommandLine.Print(_("Option is not set now."))
      end

      # maximum clients per IP
      CommandLine.PrintNoCR(_("Maximum Clients per IP: "))
      if Ops.get(FtpServer.EDIT_SETTINGS, "MaxClientsPerIP") != "0"
        CommandLine.Print(Ops.get(FtpServer.EDIT_SETTINGS, "MaxClientsPerIP"))
      else
        CommandLine.Print(_("Option is not set now."))
      end

      # maximum clients
      CommandLine.PrintNoCR(_("Maximum Number of Clients: "))
      if Ops.get(FtpServer.EDIT_SETTINGS, "MaxClientsNumber") != "0"
        CommandLine.Print(Ops.get(FtpServer.EDIT_SETTINGS, "MaxClientsNumber"))
      else
        CommandLine.Print(_("Option is not set now."))
      end

      # max rate for authenticated users
      CommandLine.PrintNoCR(_("Maximum Rate for Authenticated Users [KB/s]: "))
      if Ops.get(FtpServer.EDIT_SETTINGS, "LocalMaxRate") != "0"
        CommandLine.Print(Ops.get(FtpServer.EDIT_SETTINGS, "LocalMaxRate"))
      else
        CommandLine.Print(_("Option is not set now."))
      end

      # max rate for anonymous users
      CommandLine.PrintNoCR(_("Maximum Rate for Anonymous Users [KB/s]: "))
      if Ops.get(FtpServer.EDIT_SETTINGS, "AnonMaxRate") != "0"
        CommandLine.Print(Ops.get(FtpServer.EDIT_SETTINGS, "AnonMaxRate"))
      else
        CommandLine.Print(_("Option is not set now."))
      end

      # general settings for access
      CommandLine.PrintNoCR(_("Access Allowed for: "))
      if Ops.get(FtpServer.EDIT_SETTINGS, "AnonAuthen") == "0"
        CommandLine.Print(_("Anonymous Users"))
      elsif Ops.get(FtpServer.EDIT_SETTINGS, "AnonAuthen") == "0"
        CommandLine.Print(_("Authenticated Users"))
      elsif Ops.get(FtpServer.EDIT_SETTINGS, "AnonAuthen") == "0"
        CommandLine.Print(_("Anonymous and Authenticated Users"))
      else
        CommandLine.Print(_("Option has wrong value."))
      end

      # access permissions for anonymous users
      CommandLine.PrintNoCR(_("Access Permissions for Anonymous: "))
      if Ops.get(FtpServer.EDIT_SETTINGS, "AnonReadOnly") == "NO"
        CommandLine.PrintNoCR(_("Upload enabled; "))
      else
        CommandLine.PrintNoCR(_("Upload disabled; "))
      end
      if Ops.get(FtpServer.EDIT_SETTINGS, "AnonCreatDirs") == "YES"
        CommandLine.Print(_("Create directories enabled"))
      else
        CommandLine.Print(_("Create directories disabled"))
      end

      # welcome message vsftpd only
      CommandLine.PrintNoCR(_("Welcome message: "))
      if Ops.get(FtpServer.EDIT_SETTINGS, "Banner") != ""
        CommandLine.Print(Ops.get(FtpServer.EDIT_SETTINGS, "Banner"))
      else
        CommandLine.Print(_("Option is not set now."))
      end

      # CommandLine::PrintNoCR(_("Security settings: "));

      # SSL options (SSL version and TLS)
      if Ops.get(FtpServer.EDIT_SETTINGS, "SSLEnable") != "YES"
        CommandLine.Print(_("SSL is disabled"))
      else
        CommandLine.Print(_("SSL is enabled"))
      end

      if Ops.get(FtpServer.EDIT_SETTINGS, "TLS") != "YES"
        CommandLine.Print(_("TLS is disabled"))
      else
        CommandLine.Print(_("TLS is enabled"))
      end

      CommandLine.Print("")
      false
    end

    def FTPdCMDStartup(options)
      options = deep_copy(options)
      if !Ops.get(options, "atboot").nil? && !Ops.get(options, "manual").nil?
        # TRANSLATORS: CommandLine error message
        CommandLine.Error(_("Only one parameter (atboot/manual) is allowed."))
      elsif !Ops.get(options, "atboot").nil?
        CommandLine.Print("")
        # TRANSLATORS: CommandLine header
        CommandLine.Print(String.UnderlinedHeader(_("Start-Up:"), 0))
        CommandLine.Print("")
        # TRANSLATORS: CommandLine progress information
        CommandLine.Print(_("Enabling FTP daemon in the boot process..."))
        CommandLine.Print("")
        SetEnableService(true)
      elsif !Ops.get(options, "manual").nil?
        CommandLine.Print("")
        # TRANSLATORS: CommandLine header
        CommandLine.Print(String.UnderlinedHeader(_("Start-Up:"), 0))
        CommandLine.Print("")
        # TRANSLATORS: CommandLine progress information
        CommandLine.Print(_("Removing FTP daemon from the boot process..."))
        CommandLine.Print("")
        SetEnableService(false)
      elsif !Ops.get(options, "socket").nil?
        CommandLine.Print("")
        # TRANSLATORS: CommandLine header
        CommandLine.Print(String.UnderlinedHeader(_("Start-Up:"), 0))
        CommandLine.Print("")
        # TRANSLATORS: CommandLine progress information
        CommandLine.Print(_("Start FTP daemon via socket"))
        CommandLine.Print("")
        self.start_via_socket = true
      end
      true
    end

    def FTPdCMDLogging(options)
      options = deep_copy(options)
      if Ops.greater_than(Builtins.size(options), 1)
        # TRANSLATORS: CommandLine error message
        CommandLine.Error(_("Only one parameter (enable/disable) is allowed."))
      elsif !Ops.get(options, "enable").nil?
        Ops.set(FtpServer.EDIT_SETTINGS, "VerboseLogging", "YES")
      elsif !Ops.get(options, "disable").nil?
        Ops.set(FtpServer.EDIT_SETTINGS, "VerboseLogging", "NO")
      end # end of else if (options["show"]:nil!=nil

      nil
    end

    def FTPdCMDChrooting(options)
      options = deep_copy(options)
      if Ops.greater_than(Builtins.size(options), 1)
        # TRANSLATORS: CommandLine error message
        CommandLine.Error(_("Only one parameter (enable/disable) is allowed."))
      elsif !Ops.get(options, "enable").nil?
        Ops.set(FtpServer.EDIT_SETTINGS, "ChrootEnable", "YES")
      elsif !Ops.get(options, "disable").nil?
        Ops.set(FtpServer.EDIT_SETTINGS, "ChrootEnable", "NO")
      end # end of else if (options["show"]:nil!=nil

      nil
    end

    def FTPdCMDUmask(options)
      options = deep_copy(options)
      CommandLine.Print(String.UnderlinedHeader(_("Umask:"), 0))
      CommandLine.Print("")
      if Ops.greater_than(Builtins.size(options), 1)
        # TRANSLATORS: CommandLine error message
        CommandLine.Error(_("Only one parameter (show/set_umask) is allowed."))
      else
        if !Ops.get(options, "set_umask").nil?
          value = Ops.get_string(options, "set_umask")
          value = Builtins.filterchars(value, "01234567:")
          if value != ""
            temp = Builtins.splitstring(value, ":")
            if Ops.greater_than(Builtins.size(temp), 1)
              CommandLine.PrintNoCR(_("Umask for Anonymous: "))
              CommandLine.Print(Ops.get(temp, 0))
              CommandLine.PrintNoCR(_("Umask for Authenticated Users: "))
              CommandLine.Print(Ops.get(temp, 1))
              CommandLine.Print("")
              Ops.set(FtpServer.EDIT_SETTINGS, "UmaskAnon", Ops.get(temp, 0))
              Ops.set(FtpServer.EDIT_SETTINGS, "UmaskLocal", Ops.get(temp, 1))
            else
              CommandLine.Error(_("Entered umask is not valid."))
              CommandLine.Print(
                _(
                  "Example of correct umask <local users>:<anonymous> (177:077)"
                )
              )
              CommandLine.Print("")
            end
          else
            CommandLine.Error(_("Entered umask is not valid."))
            CommandLine.Print(
              _("Example of correct umask <local users>:<anonymous> (177:077)")
            )
            CommandLine.Print("")
          end
        end
      end

      nil
    end

    def FTPdCMDAnonDir(options)
      options = deep_copy(options)
      CommandLine.Print(String.UnderlinedHeader(_("Anonymous users:"), 0))
      CommandLine.Print("")
      if Builtins.size(options) == 1
        if !Ops.get(options, "set_anon_dir").nil?
          value = Ops.get_string(options, "set_anon_dir")
          if !value.nil?
            CommandLine.PrintNoCR(_("Anonymous directory:"))
            CommandLine.Print(value)
            CommandLine.Print("")
            Ops.set(FtpServer.EDIT_SETTINGS, "FtpDirAnon", value)
          else
            CommandLine.Error(_("Option is empty."))
            CommandLine.Print(
              _("Example of correct input set_anon_dir=/srv/ftp")
            )
            CommandLine.Print("")
          end
        end
      else
        # TRANSLATORS: CommandLine error message
        CommandLine.Error(_("Only one parameter is allowed."))
        CommandLine.Print("")
      end

      nil
    end

    def FTPdCMDPassPorts(options)
      options = deep_copy(options)
      CommandLine.Print(String.UnderlinedHeader(_("Port range:"), 0))
      CommandLine.Print("")
      if Builtins.size(options) == 2
        min_port = Ops.get_integer(options, "set_min_port")
        max_port = Ops.get_integer(options, "set_max_port")
        if !min_port.nil? && !max_port.nil?
          if Ops.less_or_equal(min_port, max_port) &&
              Ops.greater_than(max_port, 0)
            Ops.set(
              FtpServer.EDIT_SETTINGS,
              "PasMinPort",
              Builtins.tostring(min_port)
            )
            Ops.set(
              FtpServer.EDIT_SETTINGS,
              "PasMaxPort",
              Builtins.tostring(max_port)
            )
            CommandLine.PrintNoCR(_("Port range for passive mode: "))
            CommandLine.PrintNoCR(
              Ops.get(FtpServer.EDIT_SETTINGS, "PasMinPort")
            )
            CommandLine.PrintNoCR(_(" - "))
            CommandLine.Print(Ops.get(FtpServer.EDIT_SETTINGS, "PasMaxPort"))
          else
            # TRANSLATORS: CommandLine error message
            CommandLine.Error(_("Enter minimal port < maximal port."))
          end
        else
          # TRANSLATORS: CommandLine error message
          CommandLine.Error(_("Enter correct numbers."))
        end
      else
        # TRANSLATORS: CommandLine error message
        CommandLine.Error(_("Only two parameters are allowed."))
      end
      CommandLine.Print("")

      nil
    end

    def CommonHandler(options, str_key_option, map_key, underline_text, result_text)
      options = deep_copy(options)
      CommandLine.Print("")
      CommandLine.Print(String.UnderlinedHeader(underline_text, 0))
      CommandLine.Print("")
      if Builtins.size(options) == 1
        result = Ops.get_integer(options, str_key_option)
        if !result.nil?
          Ops.set(FtpServer.EDIT_SETTINGS, map_key, Builtins.tostring(result))
          CommandLine.PrintNoCR(result_text)
          CommandLine.Print(Ops.get(FtpServer.EDIT_SETTINGS, map_key))
          CommandLine.Print("")
          return true
        else
          # TRANSLATORS: CommandLine error message
          CommandLine.Error(_("Wrong value of option."))
          CommandLine.Print("")
          return false
        end
      else
        # TRANSLATORS: CommandLine error message
        CommandLine.Error(_("Only one parameter is allowed."))
        CommandLine.Print("")
        return false
      end
    end

    def FTPdCMDIdleTime(options)
      options = deep_copy(options)
      CommonHandler(
        options,
        "set_idle_time",
        "MaxIdleTime",
        "Maximal Idle Time [minutes]:",
        "Maximal Idle Time is "
      )
    end

    def FTPdCMDMaxClientsIP(options)
      options = deep_copy(options)
      CommonHandler(
        options,
        "set_max_clients",
        "MaxClientsPerIP",
        "Maximum Clients per IP:",
        "The Maximum Number of Clients per IP is "
      )
    end

    def FTPdCMDMaxClients(options)
      options = deep_copy(options)
      CommonHandler(
        options,
        "set_max_clients",
        "MaxClientsNumber",
        "Maximum Clients:",
        "The Maximum Number of Clients is "
      )
    end

    def FTPdCMDMaxRateAuthen(options)
      options = deep_copy(options)
      CommonHandler(
        options,
        "set_max_rate",
        "LocalMaxRate",
        "The Maximum Rate for Authenticated Users [KB/s]:",
        "The Maximum Rate for Authenticated Users is "
      )
    end

    def FTPdCMDMaxRateAnon(options)
      options = deep_copy(options)
      CommonHandler(
        options,
        "set_max_rate",
        "AnonMaxRate",
        "The Maximum Rate for Anonymous Users [KB/s]:",
        "The Maximum Rate for Anonymous Users is "
      )
    end

    def FTPdCMDAccess(options)
      options = deep_copy(options)
      CommandLine.Print("")
      CommandLine.Print(
        String.UnderlinedHeader(_("Access (Anonymous/Authenticated):"), 0)
      )
      CommandLine.Print("")
      if Builtins.size(options) == 1
        CommandLine.PrintNoCR(_("Access allowed for: "))
        if !Ops.get(options, "anon_only").nil?
          Ops.set(FtpServer.EDIT_SETTINGS, "AnonAuthen", "0")
          CommandLine.PrintNoCR(_("Anonymous users"))
        elsif !Ops.get(options, "authen_only").nil?
          Ops.set(FtpServer.EDIT_SETTINGS, "AnonAuthen", "1")
          CommandLine.PrintNoCR(_("Authenticated users"))
        elsif !Ops.get(options, "anon_and_authen").nil?
          Ops.set(FtpServer.EDIT_SETTINGS, "AnonAuthen", "2")
          CommandLine.PrintNoCR(_("Anonymous and authenticated users"))
        else
          # TRANSLATORS: CommandLine error message
          CommandLine.Error(_("Unknown option."))
          CommandLine.Print("")
          return false
        end
        CommandLine.Print("")
      else
        # TRANSLATORS: CommandLine error message
        CommandLine.Error(_("Only one parameter is allowed."))
        CommandLine.Print("")
        return false
      end

      nil
    end

    def FTPdCMDAnonAccess(options)
      options = deep_copy(options)
      CommandLine.Print("")
      CommandLine.Print(
        String.UnderlinedHeader(_("Access permission for anonymous users:"), 0)
      )
      CommandLine.Print("")
      if Ops.greater_than(Builtins.size(options), 0) &&
          Ops.less_or_equal(Builtins.size(options), 2)
        if !Ops.get(options, "can_upload").nil?
          Ops.set(FtpServer.EDIT_SETTINGS, "AnonReadOnly", "NO")
          CommandLine.PrintNoCR(_("Upload enabled"))
        else
          Ops.set(FtpServer.EDIT_SETTINGS, "AnonReadOnly", "YES")
          CommandLine.PrintNoCR(_("Upload disabled"))
        end
        CommandLine.PrintNoCR(_("; "))
        if !Ops.get(options, "create_dirs").nil?
          Ops.set(FtpServer.EDIT_SETTINGS, "AnonCreatDirs", "YES")
          CommandLine.PrintNoCR(_("Create dirs enabled"))
        else
          Ops.set(FtpServer.EDIT_SETTINGS, "AnonCreatDirs", "NO")
          CommandLine.PrintNoCR(_("Create dirs disabled"))
        end
      else
        # TRANSLATORS: CommandLine error message
        CommandLine.Error(_("Only one or two parameters are allowed."))
        CommandLine.Print("")
        return false
      end

      nil
    end

    def FTPdCMDWelMessage(options)
      options = deep_copy(options)
      CommandLine.Print("")
      CommandLine.Print(String.UnderlinedHeader(_("Welcome Message:"), 0))
      CommandLine.Print("")

      if Builtins.size(options) == 1
        if !Ops.get(options, "set_message").nil?
          Ops.set(
            FtpServer.EDIT_SETTINGS,
            "Banner",
            Ops.get_string(options, "set_message")
          )
          CommandLine.Print(Ops.get(FtpServer.EDIT_SETTINGS, "Banner"))
          return true
        else
          # TRANSLATORS: CommandLine error message
          CommandLine.Error(_("Missing value of option"))
          CommandLine.Print("")
          return false
        end
      else
        # TRANSLATORS: CommandLine error message
        CommandLine.Error(_("Only one parameter is allowed."))
        CommandLine.Print("")
        CommandLine.Print(
          _("Example of correct input: welcome_message=\"Hello everybody\"")
        )
        CommandLine.Print("")
        return false
      end
    end

    def CommonHandlerCheckBox(options, header, _vsftpd_deamon, name_option_EDIT_SETTINGS, general_name)
      options = deep_copy(options)
      CommandLine.Print("")
      CommandLine.Print(String.UnderlinedHeader(header, 0))
      CommandLine.Print("")
      if Builtins.size(options) == 1
        if !Ops.get(options, "enable").nil?
          Ops.set(FtpServer.EDIT_SETTINGS, name_option_EDIT_SETTINGS, "YES")
          general_name = Ops.add(general_name, " is enabled")
          CommandLine.Print(general_name)
          CommandLine.Print("")
          return true
        elsif !Ops.get(options, "disable").nil?
          Ops.set(FtpServer.EDIT_SETTINGS, name_option_EDIT_SETTINGS, "NO")
          general_name = Ops.add(general_name, " is disabled")
          CommandLine.Print(general_name)
          CommandLine.Print("")
        else
          # TRANSLATORS: CommandLine error message
          CommandLine.Error(_("Wrong option."))
          CommandLine.Print("")
          return false
        end
      else
        # TRANSLATORS: CommandLine error message
        CommandLine.Error(_("Only one parameter is allowed."))
        CommandLine.Print("")
        name_option_EDIT_SETTINGS = Ops.add(
          Ops.add("Example of correct using: ", name_option_EDIT_SETTINGS),
          " enable/disable"
        )
        CommandLine.Print(name_option_EDIT_SETTINGS)
        CommandLine.Print("")
        return false
      end

      nil
    end

    def FTPdCMDSSL(options)
      options = deep_copy(options)
      CommonHandlerCheckBox(options, "SSL:", true, "SSLEnable", "SSL")
    end

    def FTPdCMDTLS(options)
      options = deep_copy(options)
      CommonHandlerCheckBox(options, "TLS connections:", true, "TLS", "TLS")
    end

    def FTPdCMDAntiwarez(options)
      options = deep_copy(options)
      CommonHandlerCheckBox(
        options,
        "Antiwarez:",
        false,
        "AntiWarez",
        "AntiWarez"
      )
    end

    def FTPdCMDSSL_TLS(options)
      options = deep_copy(options)
      CommandLine.Print("")
      CommandLine.Print(String.UnderlinedHeader(_("Security Settings:"), 0))
      CommandLine.Print("")
      if Builtins.size(options) == 1
        if !Ops.get(options, "enable").nil?
          Ops.set(FtpServer.EDIT_SETTINGS, "SSL", "0")
          CommandLine.Print(_("SSL and TLS are enabled"))
          CommandLine.Print("")
          return true
        elsif !Ops.get(options, "disable").nil?
          Ops.set(FtpServer.EDIT_SETTINGS, "SSL", "1")
          CommandLine.Print(_("SSL and TLS are disabled"))
          CommandLine.Print("")
        elsif !Ops.get(options, "only").nil?
          Ops.set(FtpServer.EDIT_SETTINGS, "SSL", "2")
          CommandLine.Print(_("Refuse connection without SSL/TLS"))
          CommandLine.Print("")
        else
          # TRANSLATORS: CommandLine error message
          CommandLine.Error(_("Wrong option."))
          CommandLine.Print("")
          return false
        end
      else
        # TRANSLATORS: CommandLine error message
        CommandLine.Error(_("Only one parameter is allowed."))
        CommandLine.Print("")
        CommandLine.Print(
          _("Example of correct input: SSL_TLS enable/disable/only")
        )
        CommandLine.Print("")
        return false
      end

      nil
    end
  end
end

Yast::FtpServerClient.new.main
