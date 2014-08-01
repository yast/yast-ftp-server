# encoding: utf-8

# File:	modules/FtpServer.ycp
# Package:	Configuration of FtpServer
# Summary:	FtpServer settings, input and output functions
# Authors:	Jozef Uhliarik <juhliarik@suse.cz>
#
# $Id: FtpServer.ycp 27914 2006-02-13 14:32:08Z juhliarik $
#
# Representation of the configuration of FtpServer.
# Input and output routines.
require "yast"

module Yast
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
      Yast.import "SuSEFirewall"
      Yast.import "SuSEFirewallServices"
      Yast.import "PortAliases"

      # Data was modified?
      @modified = false

      # general variable for proposal
      #
      @proposal_valid = false

      # variable signifies if vsftpd is selected and
      # edited via ftp-server (YaST module)
      # global boolean variable
      @vsftpd_edit = false

      # variable signifies if vsftpd is installed and
      #
      # global boolean variable
      @vsftpd_installed = false

      # variable signifies if pure-ftpd is installed and
      #
      # global boolean variable
      @pureftpd_installed = false

      # variable signifies position vsftpd record
      # in structur Inetd::netd_conf
      # -1 init value before calling Inetd::Read()
      #
      # global integer variable
      @vsftpd_xined_id = -1

      # variable signifies if pure-ftpd is installed and
      # in structur Inetd::netd_conf
      # -1 init value before calling Inetd::Read()
      #
      # global integer variable
      @pureftpd_xined_id = -1

      # variable signifies if daemon will be started via xinetd
      #
      # global boolean variable

      @start_xinetd = false

      # variable signifies if daemon is running via xinetd
      #
      # global boolean variable

      @pure_ftp_xinetd_running = false


      # variable signifies if daemon is running via xinetd
      #
      # global boolean variable

      @vsftp_xinetd_running = false

      # variable signifies if daemon will be stoped in xinetd
      #
      # global boolean variable

      @stop_daemon_xinetd = false



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

      # variable signifies if upload dir for anonymous has good permissions
      # it is only for pure-ftpd
      #
      # -1 == home dir is "/"
      #  0 == writting access disallow
      #  1 == writting allowed
      # global integer variable

      @pure_ftp_allowed_permissios_upload = 0

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

      # list includes xinetd server_args for pure-ftpd
      #
      # global lis <string> variable

      @pure_ftpd_xinet_conf = []


      # list of keys from map DEFAULT_CONFIG
      #
      # global list <string>

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
        "SSLv2",
        "SSLv3",
        "VirtualUser",
        "FTPUser",
        "GuestUser",
        "EnableUpload"
      ]

      # map of deafult values for options in UI
      #
      # global map <string, string >

      @DEFAULT_CONFIG = {
        "ChrootEnable"     => "NO",
        "VerboseLogging"   => "NO",  # Default value for pure-ftpd.
        "log_ftp_protocol" => "YES", # Default value for vsftp (bnc#888287). 
        "FtpDirLocal"      => "", #if empty doesn't write this options via SCR
        "FtpDirAnon"       => "", #if empty doesn't write this options via SCR
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
        "SSLv2"            => "NO", #enable/disable SSL version 2 (vsftpd only)
        "SSLv3"            => "NO", #enable/disable SSL version 3 (vsftpd only)
        "TLS"              => "YES",
        "AntiWarez"        => "YES",
        "SSL"              => "0", #0 - disable SSL, 1-accept SSL, 2 - refuse connection withou SSL (pure-ftpd only)
        "StartXinetd"      => "NO",
        "StartDaemon"      => "0", #0 = start manually, 1 = start when booting, 2 = start via xinetd
        "PassiveMode"      => "YES",
        "CertFile"         => "", #cert file for SSL connections
        "VirtualUser"      => "NO",
        "FTPUser"          => "ftp",
        "GuestUser"        => "",
        "EnableUpload"     => "NO"
      }

      # map <string, string > of pure-ftpd settings
      #
      @PURE_SETTINGS = {}


      # map <string, string > of vsftpd settings
      #
      @VS_SETTINGS = {}

      # map <string, string > of vsftpd settings
      #
      @EDIT_SETTINGS = {}



      Yast.include self, "ftp-server/write_load.rb"




      @ftps = true

      # Write only, used during autoinstallation.
      # Don't run services and SuSEconfig, it's all done at one place.
      @write_only = false

      # Abort function
      # return boolean return true if abort
      @AbortFunction = fun_ref(method(:Modified), "boolean ()")
    end

    # Read current pure-ftpd configuration
    #
    #  @return [Boolean] successfull
    def ReadPUREFTPDSettings
      Builtins.foreach(SCR.Dir(path(".pure-ftpd"))) do |key|
        val = Convert.to_string(SCR.Read(Builtins.add(path(".pure-ftpd"), key)))
        #string val = (string) select((list <string>) SCR::Read(add(.pure-ftpd, key)), 0, "");
        Ops.set(@PURE_SETTINGS, key, val) if val != nil
      end

      Builtins.y2milestone("-------------PURE_SETTINGS-------------------")
      Builtins.y2milestone(
        "pure-ftpd configuration has been read: %1",
        @PURE_SETTINGS
      )
      Builtins.y2milestone("---------------------------------------------")


      true
    end

    # Read current vsftpd configuration
    #
    #  @return [Boolean] successfull

    def ReadVSFTPDSettings
      Builtins.foreach(SCR.Dir(path(".vsftpd"))) do |key|
        val = Convert.to_string(SCR.Read(Builtins.add(path(".vsftpd"), key)))
        #string val = (string) select((list <string>) SCR::Read(add(.pure-ftpd, key)), 0, "");
        Ops.set(@VS_SETTINGS, key, val) if val != nil
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
        if Ops.get(options, "exit") == 0
          result = true
        else
          result = false
        end
        if result
          #Popup::Message("Work ReadVSFTPDUpload");
          @create_upload_dir = true
          permissions = Builtins.substring(
            Builtins.tostring(Ops.get(options, "stdout")),
            0,
            10
          )
          w = Builtins.filterchars(permissions, "w")
          r = Builtins.filterchars(permissions, "r")
          if Ops.less_than(Builtins.size(w), 3) ||
              Ops.less_than(Builtins.size(r), 3)
            @upload_good_permission = false 
            #Popup::Message("good permissions");
          else
            @upload_good_permission = true 
            #Popup::Message("wrong permissions");
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
        #Popup::Message(upload_dir);
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
        #Popup::Message(directory);
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
        if Ops.get(options, "exit") == 0
          result = true
        else
          result = false
        end
        if result
          permissions = Builtins.substring(
            Builtins.tostring(Ops.get(options, "stdout")),
            0,
            10
          )
          w = Builtins.filterchars(permissions, "w")
          r = Builtins.filterchars(permissions, "r")
          if Ops.less_than(Builtins.size(w), 3) ||
              Ops.less_than(Builtins.size(r), 3)
            @pure_ftp_allowed_permissios_upload = 0 
            #Popup::Message("good permissions");
          else
            @pure_ftp_allowed_permissios_upload = 1 
            #Popup::Message("wrong permissions");
          end
        end 
        #Popup::Message(tostring(pure_ftp_allowed_permissios_upload));
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
        Ops.set(@EDIT_SETTINGS, key, val) if val != nil #if (val == nil) Popup::Message(key);;
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
      result = false
      if @vsftpd_edit
        result = ReadVSFTPDSettings()
      else
        result = ReadPUREFTPDSettings()
      end
      result = InitEDIT_SETTINGS() if result

      #read info about anonymous user "ftp"
      Users.SetGUI(false)
      if Users.Read == "" && Ops.get(@EDIT_SETTINGS, "VirtualUser") == "NO"
        if @vsftpd_edit && Ops.get(@EDIT_SETTINGS, "GuestUser") != "" &&
            Ops.get(@EDIT_SETTINGS, "FtpDirLocal") == ""
          #Popup::Message("if ((vsftpd_edit) && (EDIT_SETTINGS");
          Users.SelectUserByName(Ops.get(@EDIT_SETTINGS, "GuestUser"))
          @userinfo = Users.GetCurrentUser
          guest_home_dir = Ops.get_string(@userinfo, "homeDirectory")
          if guest_home_dir != "" && guest_home_dir != nil &&
              Ops.get(@EDIT_SETTINGS, "FtpDirLocal") == ""
            Ops.set(@EDIT_SETTINGS, "FtpDirLocal", guest_home_dir)
          end
        end
        Users.SelectUserByName(Ops.get(@EDIT_SETTINGS, "FTPUser"))
        @userinfo = Users.GetCurrentUser
        @anon_homedir = Ops.get_string(@userinfo, "homeDirectory")
        @anon_uid = Ops.get_integer(@userinfo, "uidNumber")
        #y2milestone("-------------User info-------------------");
        #y2milestone("Users :CurrentUser %1", userinfo);
        #y2milestone("---------------------------------------------");
        if @anon_homedir != "" && @anon_homedir != nil
          if Ops.get(@EDIT_SETTINGS, "FtpDirAnon") == ""
            Ops.set(@EDIT_SETTINGS, "FtpDirAnon", @anon_homedir)
          elsif Ops.get(@EDIT_SETTINGS, "FtpDirAnon") != nil
            @anon_homedir = Ops.get(@EDIT_SETTINGS, "FtpDirAnon")
          end
        end
      end
      #read firewall settings
      progress_orig = Progress.set(false)
      SuSEFirewall.Read
      Progress.set(progress_orig)
      #read existing upload directory for vsftpd
      result = ReadVSFTPDUpload() if @vsftpd_edit

      result = ReadPermisionUplaod()
      result
    end


    # Write pure-ftpd configuration to config file
    #
    # @return [Boolean] successfull
    def WritePUREFTPDSettings
      Builtins.foreach(@PURE_SETTINGS) do |option_key, option_val|
        SCR.Write(Builtins.add(path(".pure-ftpd"), option_key), option_val)
      end
      # This is very important
      # it flushes the cache, and stores the configuration on the disk
      SCR.Write(path(".pure-ftpd"), nil)

      true
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



    # Remap UI pure-ftpd or vsftpd configuration
    # to write structure for SCR
    #
    # @return [Boolean] successfull

    def WriteToSETTINGS
      Builtins.foreach(@UI_keys) { |key| ValueUI(key, true) }

      Builtins.y2milestone("-------------PURE_SETTINGS-------------------")
      Builtins.y2milestone(
        "pure-ftpd writing configuration : %1",
        @PURE_SETTINGS
      )
      Builtins.y2milestone("---------------------------------------------")

      Builtins.y2milestone("-------------VS_SETTINGS-------------------")
      Builtins.y2milestone("Vsftpd writing configuration : %1", @VS_SETTINGS)
      Builtins.y2milestone("---------------------------------------------")
      true
    end


    # Restart daemon apply changes
    # only if daemon running...
    #
    # @return [Boolean] successfull
    #boolean ApplyChanges () {




    #}


    # Write firewall configuration
    #
    # @return [Boolean] successfull

    def WriteFirewallSettings
      port_range = ""
      active_port = ""

      if SuSEFirewall.IsStarted
        if Ops.get(@EDIT_SETTINGS, "PassiveMode") == "YES"
          port_range = Ops.add(
            Ops.add(Ops.get(@EDIT_SETTINGS, "PasMinPort"), ":"),
            Ops.get(@EDIT_SETTINGS, "PasMaxPort")
          )
        else
          active_port = PortAliases.IsKnownPortName("ftp-data") ? "ftp-data" : "20"
        end

        suse_config = {
          "tcp_ports" => [
            PortAliases.IsKnownPortName("ftp") ? "ftp" : "21",
            active_port != "" ? active_port : port_range
          ]
        }

        if @vsftpd_edit
          return SuSEFirewallServices.SetNeededPortsAndProtocols(
            "service:vsftpd",
            suse_config
          )
        else
          return SuSEFirewallServices.SetNeededPortsAndProtocols(
            "service:pure-ftpd",
            suse_config
          )
        end
      else
        return true
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
      result = false
      result = WriteToSETTINGS()
      if @vsftpd_edit
        result = WriteVSFTPDSettings() if result
      else
        result = WritePUREFTPDSettings() if result
        # write homedirectory for anonymous user (ftp)
        # fto user will be change only for pure-ftpd
        # vsftpd change option anon_root
        if Ops.get(@EDIT_SETTINGS, "VirtualUser") == "NO" && !@vsftpd_edit
          if result
            if Ops.get(@EDIT_SETTINGS, "FtpDirAnon") != @anon_homedir &&
                @anon_homedir != "" &&
                @anon_homedir != nil
              error = Users.EditUser(
                { "homeDirectory" => Ops.get(@EDIT_SETTINGS, "FtpDirAnon") }
              )
              if error != nil && error != ""
                result = false
                Popup.Error(error)
              end
              if result
                if Users.CommitUser
                  Users.SetGUI(false)
                  error = Users.Write
                  if error != nil && error != ""
                    Popup.Error(error)
                    result = false
                  end
                end
              end #end of if (Users::CommitUser ()) {
            end #end of if ((EDIT_SETTINGS["FtpDirAnon"]:nil != anon_homedir) &&
          end #end of if (result) {
        end #end of if (EDIT_SETTINGS["VirtualUser"]:nil == "NO") {
      end # end of } else {

      result = WriteFirewallSettings() if result
      if result
        # write configuration to the firewall
        progress_orig = Progress.set(false)
        result = SuSEFirewall.Write
        Progress.set(progress_orig)
      end
      result
    end

    # Write current configuration
    #
    # @return [Boolean] result of function (true/false)
    def WriteXinetd
      result = false
      if @vsftpd_xined_id != -1
        result = WriteStartViaXinetd(@start_xinetd, false)
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
      options = {}
      authentication = Builtins.tointeger(Ops.get(@EDIT_SETTINGS, "AnonAuthen"))
      if @vsftpd_edit && authentication != 1 && @create_upload_dir && @upload_good_permission
        write_enable = Ops.get(@EDIT_SETTINGS, "EnableUpload") == "YES" ? true : false
        anon_upload = Ops.get(@EDIT_SETTINGS, "AnonReadOnly") == "NO" ? true : false
        anon_create_dirs = Ops.get(@EDIT_SETTINGS, "AnonCreatDirs") == "YES" ? true : false
        if write_enable && (anon_upload || anon_create_dirs)
          if Builtins.substring(
              @anon_homedir,
              Ops.subtract(Builtins.size(@anon_homedir), 1)
            ) == "/"
            upload = "upload"
          else
            upload = "/upload"
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
        if Ops.get(options, "exit") == 0
          result = true
        else
          result = false
        end 

        #Popup::Message(command);
      else
        result = true
      end
      #restart/reaload daemons...
      if @vsftpd_edit
        if Service.Status("vsftpd") == 0
          options = Convert.to_map(
            SCR.Execute(path(".target.bash_output"), "rcvsftpd restart")
          )
        end
      else
        if Service.Status("pure-ftpd") == 0
          options = Convert.to_map(
            SCR.Execute(path(".target.bash_output"), "rcpure-ftpd restart")
          )
        end
      end

      #update permissions for home directory if upload is enabled...
      if @pure_ftp_allowed_permissios_upload != -1 && @change_permissions
        if @vsftpd_edit
          command = Ops.add("chmod 755 ", @anon_homedir)
          options = Convert.to_map(
            SCR.Execute(path(".target.bash_output"), command)
          )
        else
          command = Ops.add("chmod 777 ", @anon_homedir)
          options = Convert.to_map(
            SCR.Execute(path(".target.bash_output"), command)
          )
        end
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

    #  * Abort function
    #  * @return boolean return true if abort
    #  *
    # global define boolean Abort() ``{
    #     if(AbortFunction != nil)
    #     {
    # 	return AbortFunction () == true;
    #     }
    #     return false;
    # }

    # Returns whether the configuration has been modified.
    #
    # @return [Boolean] modified
    def GetModified
      @modified
    end

    # Function set modified variable.
    #
    # @param boolean modified
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
      # FtpServer read dialog caption
      caption = _("Initializing FTP Configuration")
      steps = 2

      # Part for commandline - it is necessary choose daemon if both are installed
      if Mode.commandline
        @vsftpd_installed = Package.Installed("vsftpd")
        @pureftpd_installed = Package.Installed("pure-ftpd")

        if @vsftpd_installed && @pureftpd_installed
          if CommandLine.Interactive
            CommandLine.Print(
              String.UnderlinedHeader(_("You have installed both daemons:"), 0)
            )
            CommandLine.Print(_("Choose one of them for configuration."))
            CommandLine.Print(
              _(
                "Do you want to configure vsftpd? Alternatively choose pure-ftpd."
              )
            )
            CommandLine.Print("")
            @vsftpd_edit = true if CommandLine.YesNo
          else
            CommandLine.Error(
              _(
                "You have installed both daemons. Therefore you have to run the configuration in interactive mode."
              )
            )
            return false
          end
        end
        @vsftpd_edit = true if @vsftpd_installed && !@pureftpd_installed

        return false if !@vsftpd_installed && !@pureftpd_installed
      end

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
      ) #end of Progress::New( caption, " "

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
    # @return true on success
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
      ) #end of Progress::New(caption, " "

      # write settings
      return false if PollAbort()
      Progress.NextStage
      # write options to the config file
      Report.Error(_("Cannot write settings!")) if !WriteSettings()
      Builtins.sleep(@sl)

      return false if PollAbort()
      Progress.NextStage
      # write settings for starting daemon
      Report.Error(_("Cannot write settings for xinetd!")) if !WriteXinetd()
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
      # Progress finished
      Progress.NextStage
      Builtins.sleep(@sl)

      return false if PollAbort()
      true
    end

    # Get all FtpServer settings from the first parameter
    # (For use by autoinstallation.)
    # @param [Hash] settings The YCP structure to be imported.
    # @return [Boolean] True on success
    def Import(settings)
      settings = deep_copy(settings)
      result = true
      Builtins.foreach(@UI_keys) do |key|
        val = Ops.get_string(settings, key)
        Ops.set(@EDIT_SETTINGS, key, val) if val != nil
        if val == nil
          Ops.set(@EDIT_SETTINGS, key, Ops.get(@DEFAULT_CONFIG, key))
        end
      end 

      result
    end

    # Set which daemon will be configured
    # (For use by autoinstallation.)
    #
    # @return [Boolean] True on success
    def InitDaemon
      result = true
      #Checking if ftp daemons are installed
      rad_but = 0
      vsftpd_init_count = 0
      pureftpd_init_count = 0
      ret = nil
      if Package.Installed("vsftpd")
        vsftpd_init_count = Ops.add(vsftpd_init_count, 1)
        @vsftpd_installed = true
      end
      if Package.Installed("pure-ftpd")
        pureftpd_init_count = Ops.add(pureftpd_init_count, 1)
        @pureftpd_installed = true
      end
      if @pureftpd_installed && @vsftpd_installed
        if Service.Enabled("pure-ftpd")
          pureftpd_init_count = Ops.add(pureftpd_init_count, 1)
        end

        if Service.Enabled("vsftpd")
          vsftpd_init_count = Ops.add(vsftpd_init_count, 1)
        end

        #Checking status of ftp daemons

        if Service.Status("vsftpd") == 0
          vsftpd_init_count = Ops.add(vsftpd_init_count, 1)
        end

        if Service.Status("pure-ftpd") == 0
          pureftpd_init_count = Ops.add(pureftpd_init_count, 1)
        end

        if pureftpd_init_count == vsftpd_init_count
          @vsftpd_edit = false
        elsif Ops.less_than(pureftpd_init_count, vsftpd_init_count)
          @vsftpd_edit = false
        else
          @vsftpd_edit = true
        end
      elsif @pureftpd_installed && !@vsftpd_installed
        result = true
        @vsftpd_edit = false
      elsif !@pureftpd_installed && @vsftpd_installed
        result = true
        @vsftpd_edit = true
      else
        result = true
        @vsftpd_edit = false
      end
      result
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
      option = ""
      #start FTP daemon
      value = Ops.get(@EDIT_SETTINGS, "StartDaemon")
      if value == "0"
        option = "manually"
      elsif value == "1"
        option = "via xinetd"
      else
        option = "via inetd"
      end
      _S = Builtins.sformat("%1<li>Start Deamon: <i>(%2)</i>", _S, option)
      value = Ops.get(@EDIT_SETTINGS, "AnonAuthen")
      if value == "0"
        option = "Anonymous Only"
      elsif value == "1"
        option = "Authenticated Only"
      else
        option = "Both"
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
      if Builtins.size(@EDIT_SETTINGS) == 0
        # Translators: Summary head, if nothing configured
        _S = Summary.AddHeader(_S, _("FTP daemon"))
        _S = Summary.AddLine(_S, Summary.NotConfigured)
      else
        # Translators: Summary head, if something configured
        head = Builtins.sformat(
          _("FTP daemon %1"),
          @vsftpd_edit ? "vsftpd" : "pure-ftpd"
        )
        _S = Summary.AddHeader(_S, head)
        _S = Summary.AddHeader(_S, _("These options will be configured"))
        _S = Builtins.sformat("%1<ul>%2</ul></p>", _S, OptionsSummary())
      end
      _S
    end

    # Create an overview table with all configured cards
    # @return table items
    def Overview
      []
    end

    #zzz
    # Return packages needed to be installed and removed during
    # Autoinstallation to insure module has all needed software
    # installed.
    # @return [Hash] with 2 lists.
    def AutoPackages
      if @vsftpd_edit
        return { "install" => ["vsftpd"], "remove" => [] }
      else
        return { "install" => ["pure-ftpd"], "remove" => [] }
      end
    end

    publish :function => :SetModified, :type => "void (boolean)"
    publish :function => :Modified, :type => "boolean ()"
    publish :function => :WriteToEditMap, :type => "boolean (string, string)"
    publish :function => :WriteSettings, :type => "boolean ()"
    publish :function => :WriteUpload, :type => "boolean ()"
    publish :function => :WriteXinetd, :type => "boolean ()"
    publish :variable => :modified, :type => "boolean"
    publish :variable => :proposal_valid, :type => "boolean"
    publish :variable => :vsftpd_edit, :type => "boolean"
    publish :variable => :vsftpd_installed, :type => "boolean"
    publish :variable => :pureftpd_installed, :type => "boolean"
    publish :variable => :vsftpd_xined_id, :type => "integer"
    publish :variable => :pureftpd_xined_id, :type => "integer"
    publish :variable => :start_xinetd, :type => "boolean"
    publish :variable => :pure_ftp_xinetd_running, :type => "boolean"
    publish :variable => :vsftp_xinetd_running, :type => "boolean"
    publish :variable => :stop_daemon_xinetd, :type => "boolean"
    publish :variable => :create_upload_dir, :type => "boolean"
    publish :variable => :upload_good_permission, :type => "boolean"
    publish :variable => :pure_ftp_allowed_permissios_upload, :type => "integer"
    publish :variable => :change_permissions, :type => "boolean"
    publish :variable => :anon_homedir, :type => "string"
    publish :variable => :anon_uid, :type => "integer"
    publish :variable => :pure_ftpd_xinet_conf, :type => "list <string>"
    publish :variable => :UI_keys, :type => "list <string>"
    publish :variable => :DEFAULT_CONFIG, :type => "map <string, string>"
    publish :variable => :PURE_SETTINGS, :type => "map <string, string>"
    publish :variable => :VS_SETTINGS, :type => "map <string, string>"
    publish :variable => :EDIT_SETTINGS, :type => "map <string, string>"
    publish :function => :PureSettingsForXinetd, :type => "string ()"
    publish :function => :WriteStartViaXinetd, :type => "boolean (boolean, boolean)"
    publish :function => :ValueUI, :type => "string (string, boolean)"
    publish :function => :ValueUIEdit, :type => "string (string)"
    publish :variable => :ftps, :type => "boolean"
    publish :variable => :write_only, :type => "boolean"
    publish :variable => :AbortFunction, :type => "boolean ()"
    publish :function => :GetModified, :type => "boolean ()"
    publish :function => :Abort, :type => "boolean ()"
    publish :function => :PollAbort, :type => "boolean ()"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
    publish :function => :Import, :type => "boolean (map)"
    publish :function => :InitDaemon, :type => "boolean ()"
    publish :function => :Export, :type => "map ()"
    publish :function => :OptionsSummary, :type => "string ()"
    publish :function => :Summary, :type => "string ()"
    publish :function => :Overview, :type => "list ()"
    publish :function => :AutoPackages, :type => "map ()"
  end

  FtpServer = FtpServerClass.new
  FtpServer.main
end
