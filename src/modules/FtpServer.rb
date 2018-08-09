# encoding: utf-8

require "yast"
require "yast2/system_service"
require "y2firewall/firewalld"

module Yast
  # Configure vsftpd: https://security.appspot.com/vsftpd.html
  class FtpServerClass < Module
    def main
      Yast.import "UI"
      textdomain "ftp-server"

      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Summary"
      Yast.import "Message"
      Yast.import "Popup"
      Yast.import "String"
      Yast.import "Mode"
      Yast.import "Package"
      Yast.import "CommandLine"
      Yast.import "Users"
      Yast.import "PortAliases"

      # Data was modified?
      @modified = false

      # general variable for proposal
      #
      @proposal_valid = false

      # variable signifies if vsftpd is installed and
      #
      # global boolean variable
      @vsftpd_installed = false

      # how to start ftp server. Possibilities are :no, :service and :socket
      @start = :no

      # variable signifies if it is create upload dir
      # only for vsftpd and anonymous connections with allowed upload
      #
      # global boolean variable

      @create_upload_dir = false

      # variable signifies if upload dir has good permissions
      # only for vsftpd and anonymous connections with allowed upload
      #
      # global boolean variable

      @upload_good_permission = false

      # variable signifies if user choose change permissions for home dir
      # for anonymous connections with allowed upload
      #
      # global boolean variable

      @change_permissions = false

      # variable signifies home dir for anonymous user
      #
      # global string variable

      @anon_homedir = ""

      # variable signifies uid for anonymous user
      #
      # global integer variable

      @anon_uid = 0

      # variable signifies sleep time during reading settings
      #
      # internal integer variable

      @sl = 500

      # variable includes user info about anonymous user
      #
      # internal map variable
      @userinfo = {}

      @UI_keys = [
        "ChrootEnable",
        "VerboseLogging",
        "FtpDirLocal",
        "FtpDirAnon",
        "Umask",
        "UmaskAnon",
        "UmaskLocal",
        "PasMinPort",
        "PasMaxPort",
        "MaxIdleTime",
        "MaxClientsPerIP",
        "MaxClientsNumber",
        "LocalMaxRate",
        "AnonMaxRate",
        "AnonAuthen",
        "AnonReadOnly",
        "AnonCreatDirs",
        "Banner",
        "SSLEnable",
        "TLS",
        "AntiWarez",
        "SSL",
        "StartXinetd",
        "PassiveMode",
        "CertFile",
        "VirtualUser",
        "FTPUser",
        "GuestUser",
        "EnableUpload"
      ]

      @DEFAULT_CONFIG = {
        "ChrootEnable"     => "NO",
        "VerboseLogging"   => "NO",  # Default value for pure-ftpd.
        "log_ftp_protocol" => "YES", # Default value for vsftp (bnc#888287).
        "FtpDirLocal"      => "", # if empty doesn't write this options via SCR
        "FtpDirAnon"       => "", # if empty doesn't write this options via SCR
        "Umask"            => "",
        "UmaskAnon"        => "",
        "UmaskLocal"       => "",
        "PasMinPort"       => "40000",
        "PasMaxPort"       => "40500",
        "MaxIdleTime"      => "15",
        "MaxClientsPerIP"  => "3",
        "MaxClientsNumber" => "10",
        "LocalMaxRate"     => "0",
        "AnonMaxRate"      => "0",
        "AnonAuthen"       => "1", # 0 => anonymous only, 1 => authenticated only, 2=> both
        "AnonReadOnly"     => "YES",
        "AnonCreatDirs"    => "NO",
        "Banner"           => _("Welcome message"),
        "SSLEnable"        => "NO",
        "TLS"              => "YES",
        "AntiWarez"        => "YES",
        "SSL"              => "0", # 0 - disable SSL, 1-accept SSL
        "StartDaemon"      => "0", # 0 = start manually, 1 = start when booting, 2 = start via socket
        "PassiveMode"      => "YES",
        "CertFile"         => "", # cert file for SSL connections
        "VirtualUser"      => "NO",
        "FTPUser"          => "ftp",
        "GuestUser"        => "",
        "EnableUpload"     => "NO"
      }

      @VS_SETTINGS = {}
      @EDIT_SETTINGS = {}

      Yast.include self, "ftp-server/write_load.rb"

      @ftps = true

      # Write only, used during autoinstallation.
      # Don't run services and SuSEconfig, it's all done at one place.
      @write_only = false
    end

    def service
      @service ||= Yast2::SystemService.find("vsftpd")
    end

    def firewalld
      @firewalld ||= Y2Firewall::Firewalld.instance
    end

    # Read current vsftpd configuration
    #
    #  @return [Boolean] successfull
    def ReadVSFTPDSettings
      Builtins.foreach(SCR.Dir(path(".vsftpd"))) do |key|
        val = Convert.to_string(SCR.Read(Builtins.add(path(".vsftpd"), key)))
        Ops.set(@VS_SETTINGS, key, val) if !val.nil?
      end
      Builtins.y2milestone("-------------VS_SETTINGS-------------------")
      Builtins.y2milestone(
        "VSFTPD configuration has been read: %1",
        @VS_SETTINGS
      )
      Builtins.y2milestone("---------------------------------------------")

      true
    end

    # Read vsftpd configuration
    # existing upload file and permissions
    #
    #  @return [Boolean] successfull
    def ReadVSFTPDUpload
      result = false
      command = ""
      if @anon_homedir != ""
        command = Ops.add(Ops.add("ls -l ", @anon_homedir), " | grep upload")
      end
      if command != ""
        options = Convert.to_map(
          SCR.Execute(path(".target.bash_output"), command)
        )
        Builtins.y2milestone(
          "[ftp-server] (ReadVSFTPDUpload) command for existing upload dir:  %1  output: %2",
          command,
          options
        )
        result = if Ops.get(options, "exit").zero?
          true
        else
          false
        end
        if result
          @create_upload_dir = true
          permissions = Builtins.substring(
            Builtins.tostring(Ops.get(options, "stdout")),
            0,
            10
          )
          w = Builtins.filterchars(permissions, "w")
          r = Builtins.filterchars(permissions, "r")
          @upload_good_permission = if Ops.less_than(Builtins.size(w), 3) ||
              Ops.less_than(Builtins.size(r), 3)
            false
          else
            true
          end
        end
      end

      result
    end

    # Read pure-fptd configuration
    # checking permissions for upload
    #
    #  @return [Boolean] successfull
    def ReadPermisionUplaod
      result = false
      command = ""
      directory = ""
      upload_dir = ""

      directories = Builtins.filter(Builtins.splitstring(@anon_homedir, "/")) do |key|
        key != ""
      end

      Builtins.y2milestone(
        "[ftp-server] (ReadPermisionUplaod) split directories...:  %1 ",
        directories
      )

      if Builtins.size(directories) == 1
        directory = "/"
        upload_dir = Builtins.deletechars(@anon_homedir, "/")
      elsif Ops.greater_than(Builtins.size(directories), 1)
        upload_dir = Ops.get(
          directories,
          Ops.subtract(Builtins.size(directories), 1),
          ""
        )
        directory = Ops.add(
          "/",
          Builtins.mergestring(
            Builtins.remove(
              directories,
              Ops.subtract(Builtins.size(directories), 1)
            ),
            "/"
          )
        )
      else
        @pure_ftp_allowed_permissios_upload = -1
      end

      if @anon_homedir != "" && @pure_ftp_allowed_permissios_upload != -1
        command = Ops.add(
          Ops.add(Ops.add("ls -l ", directory), " | grep "),
          upload_dir
        )
      end
      if command != ""
        options = Convert.to_map(
          SCR.Execute(path(".target.bash_output"), command)
        )
        Builtins.y2milestone(
          "[ftp-server] (ReadPermisionUplaod) command for checking permissions for upload dir:  %1",
          command
        )
        result = if Ops.get(options, "exit").zero?
          true
        else
          false
        end
        if result
          permissions = Builtins.substring(
            Builtins.tostring(Ops.get(options, "stdout")),
            0,
            10
          )
          w = Builtins.filterchars(permissions, "w")
          r = Builtins.filterchars(permissions, "r")
          @pure_ftp_allowed_permissios_upload = if Ops.less_than(Builtins.size(w), 3) ||
              Ops.less_than(Builtins.size(r), 3)
            0
          else
            1
          end
        end
      end
      result
    end

    # Remap current pure -FtpServer configuration
    # to temporary structure
    #
    # @return [Boolean] successfull
    def InitEDIT_SETTINGS
      Builtins.foreach(@UI_keys) do |key|
        val = ValueUI(key, false)
        Ops.set(@EDIT_SETTINGS, key, val) if !val.nil?
      end

      Builtins.y2milestone("-------------EDIT_SETTINGS-------------------")
      Builtins.y2milestone(
        "EDIT_SETTINGS configuration has been read: %1",
        @EDIT_SETTINGS
      )
      Builtins.y2milestone("---------------------------------------------")

      true
    end

    # Read current configuration
    #
    # @return [Boolean] successfull
    def ReadSettings
      result = ReadVSFTPDSettings()
      result = InitEDIT_SETTINGS() if result

      # read info about anonymous user "ftp"
      Users.SetGUI(false)
      if Users.Read == "" && Ops.get(@EDIT_SETTINGS, "VirtualUser") == "NO"
        if Ops.get(@EDIT_SETTINGS, "GuestUser") != "" &&
            Ops.get(@EDIT_SETTINGS, "FtpDirLocal") == ""
          Users.SelectUserByName(Ops.get(@EDIT_SETTINGS, "GuestUser"))
          @userinfo = Users.GetCurrentUser
          guest_home_dir = Ops.get_string(@userinfo, "homeDirectory")
          if guest_home_dir != "" && !guest_home_dir.nil? &&
              Ops.get(@EDIT_SETTINGS, "FtpDirLocal") == ""
            Ops.set(@EDIT_SETTINGS, "FtpDirLocal", guest_home_dir)
          end
        end
        Users.SelectUserByName(Ops.get(@EDIT_SETTINGS, "FTPUser"))
        @userinfo = Users.GetCurrentUser
        @anon_homedir = Ops.get_string(@userinfo, "homeDirectory")
        @anon_uid = Ops.get_integer(@userinfo, "uidNumber")
        # y2milestone("-------------User info-------------------");
        # y2milestone("Users :CurrentUser %1", userinfo);
        # y2milestone("---------------------------------------------");
        if @anon_homedir != "" && !@anon_homedir.nil?
          if Ops.get(@EDIT_SETTINGS, "FtpDirAnon") == ""
            Ops.set(@EDIT_SETTINGS, "FtpDirAnon", @anon_homedir)
          elsif !Ops.get(@EDIT_SETTINGS, "FtpDirAnon").nil?
            @anon_homedir = Ops.get(@EDIT_SETTINGS, "FtpDirAnon")
          end
        end
      end
      read_daemon
      # read firewall settings
      progress_orig = Progress.set(false)
      firewalld.read
      Progress.set(progress_orig)
      # read existing upload directory for vsftpd
      result = ReadVSFTPDUpload() && result

      result = ReadPermisionUplaod() && result
      result
    end

    def read_daemon
      FtpServer.EDIT_SETTINGS["StartDaemon"] = if start_via_socket?
        "2"
      elsif Service.active?("vsftpd")
        "1"
      else
        "0"
      end
    end

    def write_daemon
      case FtpServer.EDIT_SETTINGS["StartDaemon"]
      when "2"
        FtpServer.WriteStartViaSocket(true)
        Service.disable("vsftpd")
        Service.stop("vsftpd") # stop to force load of new service with new config
      when "1"
        FtpServer.WriteStartViaSocket(false)
        Service.enable("vsftpd")
        Service.start("vsftpd")
      when "0"
        FtpServer.WriteStartViaSocket(false)
        Service.disable("vsftpd")
        Service.stop("vsftpd")
      else
        raise "Invalid value for start deamon '#{FtpServer.EDIT_SETTINGS["StartDaemon"].inspect}'"
      end
    end

    # Write vsftpd configuration to config file
    #
    # @return [Boolean] successfull
    def WriteVSFTPDSettings
      Builtins.foreach(@VS_SETTINGS) do |option_key, option_val|
        SCR.Write(Builtins.add(path(".vsftpd"), option_key), option_val)
      end
      # This is very important
      # it flushes the cache, and stores the configuration on the disk
      SCR.Write(path(".vsftpd"), nil)

      true
    end

    # Remap UI vsftpd configuration
    # to write structure for SCR
    #
    # @return [Boolean] successfull
    def WriteToSETTINGS
      Builtins.foreach(@UI_keys) { |key| ValueUI(key, true) }

      Builtins.y2milestone("-------------VS_SETTINGS-------------------")
      Builtins.y2milestone("Vsftpd writing configuration : %1", @VS_SETTINGS)
      Builtins.y2milestone("---------------------------------------------")
      true
    end

    # Write firewall configuration
    #
    # @return [Boolean] successfull
    def WriteFirewallSettings
      port_range = ""
      active_port = ""

      return true if !firewalld.running?

      if Ops.get(@EDIT_SETTINGS, "PassiveMode") == "YES"
        port_range = "#{@EDIT_SETTINGS["PasMinPort"]}-#{@EDIT_SETTINGS["PasMaxPort"]}"
      else
        active_port = PortAliases.IsKnownPortName("ftp-data") ? "ftp-data" : "20"
      end

      tcp_ports = [
        PortAliases.IsKnownPortName("ftp") ? "ftp" : "21",
        active_port != "" ? active_port : port_range
      ]

      service = "vsftpd"

      begin
        return Y2Firewall::Firewalld::Service.modify_ports(name: service, tcp_ports: tcp_ports)
      rescue Y2Firewall::Firewalld::Service::NotFound
        y2error("Firewalld 'vsftpd' service is not available.")
        return false
      end
    end

    # Write value from UI
    # to temporary structure
    #
    # @param [String] key of EDIT_SETTINGS map
    # @param [String] value of "key" EDIT_SETTINGS map
    # @return [Boolean] successfull
    def WriteToEditMap(key, value)
      Ops.set(@EDIT_SETTINGS, key, value)
      true
    end

    # Write current configuration
    #
    # @return [Boolean] successfull
    def WriteSettings
      result = WriteToSETTINGS() && WriteVSFTPDSettings()

      result &&= WriteFirewallSettings()
      if result
        # write configuration to the firewall
        progress_orig = Progress.set(false)
        result = firewalld.write
        Progress.set(progress_orig)
      end
      result
    end

    # Ask for creation upload directory
    # It is necessary if user want to allow uploading for anonymous
    # @return [Boolean] result of function (true/false)
    def WriteUpload
      result = true
      command = ""
      upload = ""
      authentication = Builtins.tointeger(Ops.get(@EDIT_SETTINGS, "AnonAuthen"))
      if authentication != 1 && @create_upload_dir && @upload_good_permission
        write_enable = Ops.get(@EDIT_SETTINGS, "EnableUpload") == "YES" ? true : false
        anon_upload = Ops.get(@EDIT_SETTINGS, "AnonReadOnly") == "NO" ? true : false
        anon_create_dirs = Ops.get(@EDIT_SETTINGS, "AnonCreatDirs") == "YES" ? true : false
        if write_enable && (anon_upload || anon_create_dirs)
          upload = if Builtins.substring(
            @anon_homedir,
            Ops.subtract(Builtins.size(@anon_homedir), 1)
          ) == "/"
            "upload"
          else
            "/upload"
          end
        end
        command = "dir=`ls "
        command = Ops.add(command, @anon_homedir)
        command = Ops.add(
          command,
          " | grep upload`; if [ -z $dir ]; then mkdir "
        )
        command = Ops.add(
          Ops.add(Ops.add(command, @anon_homedir), upload),
          "; chown "
        )

        if Ops.get(@EDIT_SETTINGS, "GuestUser") != ""
          command = Ops.add(
            Ops.add(Ops.add(command, Ops.get(@EDIT_SETTINGS, "GuestUser")), ":"),
            Ops.get(@EDIT_SETTINGS, "GuestUser")
          )
        elsif Ops.get(@EDIT_SETTINGS, "FTPUser") != ""
          command = Ops.add(
            Ops.add(Ops.add(command, Ops.get(@EDIT_SETTINGS, "FTPUser")), ":"),
            Ops.get(@EDIT_SETTINGS, "FTPUser")
          )
        end

        command = Ops.add(
          Ops.add(Ops.add(Ops.add(command, " "), @anon_homedir), upload),
          "; chmod 766 "
        )
        command = Ops.add(
          Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(Ops.add(command, @anon_homedir), upload),
                "; else chmod 766 "
              ),
              @anon_homedir
            ),
            upload
          ),
          "; fi"
        )
        # "dir=`ls /srv/ftp/ | grep upload`; if [ -z $dir ]; then echo $dir; mkdir /srv/ftp/upload;
        #  chown ftp:ftp /srv/ftp/upload/; chmod 755 /srv/ftp/upload; else chmod 766 /srv/ftp/upload/; fi"
        Builtins.y2milestone(
          "[ftp-server] (WriteUpload) bash command for creating upload dir : %1",
          command
        )
        options = Convert.to_map(
          SCR.Execute(path(".target.bash_output"), command)
        )
        result = if Ops.get(options, "exit").zero?
          true
        else
          false
        end
      else
        result = true
      end
      # restart/reaload daemons...
      Service.restart("vsftpd") if Service.active?("vsftpd")

      # update permissions for home directory if upload is enabled...
      if @pure_ftp_allowed_permissios_upload != -1 && @change_permissions
        command = Ops.add("chmod 755 ", @anon_homedir)
        SCR.Execute(path(".target.bash_output"), command)
      end

      result
    end

    # read value from  PURE_EDIT_SETTINGS
    #
    # @param [String] key for edit map (ID of option)
    # @return [String] value of key from edit map
    def ValueUIEdit(key)
      Ops.get(@EDIT_SETTINGS, key)
    end

    # Returns whether the configuration has been modified.
    #
    # @return [Boolean] modified
    def GetModified
      @modified
    end

    # Function set {#modified} variable.
    #
    # @param [Boolean] set_modified
    def SetModified(set_modified)
      @modified = set_modified

      nil
    end

    # Returns a confirmation popup dialog whether user wants to really abort.
    #
    # @return [Boolean] result of Popup::ReallyAbort(GetModified()
    def Abort
      Popup.ReallyAbort(GetModified())
    end

    # Checks whether an Abort button has been pressed.
    # If so, calls function to confirm the abort call.
    #
    # @return [Boolean] true if abort confirmed
    def PollAbort
      return false if Mode.commandline
      return Abort() if UI.PollInput == :abort

      false
    end

    # Data was modified?
    # @return true if modified
    def Modified
      Builtins.y2debug("modified=%1", @modified)
      @modified
    end

    # Read all FtpServer settings
    # @return true on success
    def Read
      Package.InstallAll(["vsftpd"]) # ensure it is there
      # FtpServer read dialog caption
      caption = _("Initializing FTP Configuration")
      steps = 2

      # Part for commandline - it is necessary choose daemon if both are installed
      @vsftpd_installed = Package.Installed("vsftpd") if Mode.commandline

      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        steps,
        [
          # Progress stage 1/2
          _("Read settings from the config file"),
          # Progress stage 2/2
          _("Read the previous settings")
        ],
        [
          # Progress stage 1/2
          _("Reading the settings..."),
          Message.Finished
        ],
        ""
      ) # end of Progress::New( caption, " "

      # read settings
      return false if PollAbort()
      Progress.NextStage
      # calling read function for reading settings form config file
      Report.Error(_("Cannot Read Current Settings.")) if !ReadSettings()
      Builtins.sleep(@sl)

      return false if PollAbort()
      # Progress finished
      Progress.NextStage
      Builtins.sleep(@sl)

      return false if PollAbort()
      @modified = false
      true
    end

    # Write all FtpServer settings
    #
    # @return [Boolean] true on success; false otherwise
    def Write
      # FtpServer read dialog caption
      caption = _("Saving FTP Configuration")
      steps = 3

      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        steps,
        [
          # Progress stage 1/2
          _("Write the settings to the config file"),
          # Progress stage 2/2
          _("Write the settings for starting daemon")
        ],
        [
          # Progress step 1/1
          _("Writing the settings..."),
          Message.Finished
        ],
        ""
      ) # end of Progress::New(caption, " "

      # write settings
      return false if PollAbort()
      Progress.NextStage
      # write options to the config file
      Report.Error(_("Cannot write settings!")) if !WriteSettings()
      Builtins.sleep(@sl)

      return false if PollAbort()
      Progress.NextStage
      # write settings for starting daemon
      if !WriteUpload()
        Report.Error(
          _("Cannot create upload directory for anonymous connections.")
        )
      end
      Builtins.sleep(@sl)

      return false if PollAbort()

      result = save_status

      # Progress finished
      Progress.NextStage
      Builtins.sleep(@sl)

      return false if PollAbort()

      result
    end

    # Saves service status (start mode and starts/stops the service)
    #
    # @note For AutoYaST and for command line actions, it uses the old way
    #   for backward compatibility, see {#write_daemon}. When the service
    #   is configured by using the UI, it directly saves the service, see
    #   Yast2::SystemService#save.
    def save_status
      if Mode.auto || Mode.commandline
        write_daemon
        true
      else
        service.save
      end
    end

    # Get all FtpServer settings from the first parameter
    # (For use by autoinstallation.)
    # @param [Hash] settings The YCP structure to be imported.
    # @return [Boolean] True on success
    def Import(settings)
      settings = deep_copy(settings)
      # ...and check/initialize the correct ftpserver which will
      # be used for configuration.
      # (bnc#907354)
      InitDaemon()

      result = true

      # StartDaemon setting is not a part of the general UI but is needed
      # for the AutoYaST installation and is set in the AY configuration
      # file. So we have to add it here too. (bnc#1047232)
      Builtins.foreach(@UI_keys + ["StartDaemon"]) do |key|
        val = Ops.get_string(settings, key)
        Ops.set(@EDIT_SETTINGS, key, val) if !val.nil?
        Ops.set(@EDIT_SETTINGS, key, Ops.get(@DEFAULT_CONFIG, key)) if val.nil?
      end

      result
    end

    # Set which daemon will be configured
    # (For use by autoinstallation.)
    #
    # @return [Boolean] True on success
    def InitDaemon
      @vsftpd_installed = true if Package.Installed("vsftpd")

      true
    end

    # Dump the FtpServer settings to a single map
    # (For use by autoinstallation.)
    # @return [Hash] Dumped settings (later acceptable by Import ())
    def Export
      deep_copy(@EDIT_SETTINGS)
    end

    # Create unsorted list of options
    # @return [String] Returnes string with RichText-formated list
    def OptionsSummary
      _S = ""
      # start FTP daemon
      value = Ops.get(@EDIT_SETTINGS, "StartDaemon")
      option = if value == "0"
        "manually"
      elsif value == "1"
        "via service"
      else
        "via socket"
      end
      _S = Builtins.sformat("%1<li>Start Deamon: <i>(%2)</i>", _S, option)
      value = Ops.get(@EDIT_SETTINGS, "AnonAuthen")
      option = if value == "0"
        "Anonymous Only"
      elsif value == "1"
        "Authenticated Only"
      else
        "Both"
      end
      _S = Builtins.sformat("%1<li>Access: <i>(%2)</i>", _S, option)
      # anonymous dir
      if value != "1"
        _S = Builtins.sformat(
          "%1<li>Anonymous Directory: <i>(%2)</i>",
          _S,
          Ops.get(@EDIT_SETTINGS, "FtpDirAnon")
        )
        _S = Builtins.sformat(
          "%1<li>Anonymous Read Only: <i>(%2)</i>",
          _S,
          Ops.get(@EDIT_SETTINGS, "AnonReadOnly")
        )
        _S = Builtins.sformat(
          "%1<li>Anonymous Can Create Directory: <i>(%2)</i>",
          _S,
          Ops.get(@EDIT_SETTINGS, "AnonCreatDirs")
        )
      end
      _S = _("<p><ul><i>FTP daemon is not configured.</i></ul></p>") if _S == ""
      _S
    end

    # Create a textual summary and a list of unconfigured cards
    # @return summary of the current configuration
    def Summary
      _S = ""
      if Builtins.size(@EDIT_SETTINGS).zero?
        # Translators: Summary head, if nothing configured
        _S = Summary.AddHeader(_S, _("FTP daemon"))
        _S = Summary.AddLine(_S, Summary.NotConfigured)
      else
        # Translators: Summary head, if something configured
        head = Builtins.sformat(
          _("FTP daemon %1"),
          "vsftpd"
        )
        _S = Summary.AddHeader(_S, head)
        _S = Summary.AddHeader(_S, _("These options will be configured"))
        _S = Builtins.sformat("%1<ul>%2</ul></p>", _S, OptionsSummary())
      end
      _S
    end

    # zzz
    # Return packages needed to be installed and removed during
    # Autoinstallation to insure module has all needed software
    # installed.
    # @return [Hash] with 2 lists.
    def AutoPackages
      { "install" => ["vsftpd"], "remove" => [] }
    end

    # This helper allows YARD to extract DSL-defined attributes.
    # Unfortunately YARD has problems with the Capitalized ones,
    # so those must be done manually.
    # @!macro [attach] publish_variable
    #   @!attribute $1
    #   @return [$2]
    def self.publish_variable(name, type)
      publish variable: name, type: type
    end

    publish function: :SetModified, type: "void (boolean)"
    publish function: :Modified, type: "boolean ()"
    publish function: :WriteToEditMap, type: "boolean (string, string)"
    publish function: :WriteSettings, type: "boolean ()"
    publish function: :WriteUpload, type: "boolean ()"
    publish_variable :modified, "boolean"
    publish_variable :proposal_valid, "boolean"
    publish_variable :vsftpd_installed, "boolean"
    publish_variable :vsftpd_xined_id, "integer"
    publish_variable :create_upload_dir, "boolean"
    publish_variable :upload_good_permission, "boolean"
    publish_variable :pure_ftp_allowed_permissios_upload, "integer"
    publish_variable :change_permissions, "boolean"
    publish_variable :anon_homedir, "string"
    publish_variable :anon_uid, "integer"

    # @attribute [r] UI_keys
    # @return [Array<String>]
    # A list of setting keys yast cares about,
    # in the {#EDIT_SETTINGS} vocabulary.
    # It should be made a constant.
    publish variable: :UI_keys, type: "list <string>"

    # @attribute DEFAULT_CONFIG
    # @return [Hash<String,String>]
    # Defaults for {#EDIT_SETTINGS} in case the value is not found
    # in the system settings.
    publish variable: :DEFAULT_CONFIG, type: "map <string, string>"

    # @attribute VS_SETTINGS
    # @return [Hash<String,String>]
    # Uses snake_case, {FtpServerWriteLoadInclude#ValueUI ValueUI} maps it
    # to {#EDIT_SETTINGS} and {#DEFAULT_CONFIG}.
    publish variable: :VS_SETTINGS, type: "map <string, string>"

    # @attribute EDIT_SETTINGS
    # @return [Hash<String,String>]
    publish variable: :EDIT_SETTINGS, type: "map <string, string>"

    publish function: :ValueUI, type: "string (string, boolean)"
    publish function: :ValueUIEdit, type: "string (string)"
    publish_variable :ftps, "boolean"
    publish_variable :write_only, "boolean"
    publish function: :GetModified, type: "boolean ()"
    publish function: :Abort, type: "boolean ()"
    publish function: :PollAbort, type: "boolean ()"
    publish function: :Read, type: "boolean ()"
    publish function: :Write, type: "boolean ()"
    publish function: :Import, type: "boolean (map)"
    publish function: :InitDaemon, type: "boolean ()"
    publish function: :Export, type: "map ()"
    publish function: :OptionsSummary, type: "string ()"
    publish function: :Summary, type: "string ()"
    publish function: :AutoPackages, type: "map ()"
  end

  FtpServer = FtpServerClass.new
  FtpServer.main
end
