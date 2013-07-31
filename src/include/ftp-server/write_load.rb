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
module Yast
  module FtpServerWriteLoadInclude
    def initialize_ftp_server_write_load(include_target)
      textdomain "ftp-server"

      Yast.import "Service"
      Yast.import "Popup"
      Yast.import "Inetd"
      Yast.import "Progress"
    end

    def IdFTPXinetd
      old_progress = Progress.set(false)
      ret = Inetd.Read
      Progress.set(old_progress)
      if ret
        value = ""
        i = 0
        ids = ""
        while Ops.greater_than(Builtins.size(Inetd.netd_conf), i)
          ids = Builtins.tostring(Ops.get(Inetd.netd_conf, [i, "iid"]))
          if Builtins.regexpmatch(ids, "vsftpd")
            @vsftpd_xined_id = i
          elsif Builtins.regexpmatch(ids, "pure-ftpd")
            @pureftpd_xined_id = i
          end
          i = Ops.add(i, 1)
        end # while (size(Inetd::netd_conf) > i) {
        if Ops.greater_than(@pureftpd_xined_id, -1)
          server_args = Ops.get_string(
            Inetd.netd_conf,
            [@pureftpd_xined_id, "server_args"]
          )
          @pure_ftpd_xinet_conf = Builtins.splitstring(server_args, " ")
          Builtins.y2milestone(
            "-------------PURE_SETTINGS_XINETD-------------------"
          )
          Builtins.y2milestone(
            "pure-ftpd configuration has been read from xinetd: %1",
            @pure_ftpd_xinet_conf
          )
          Builtins.y2milestone(
            "----------------------------------------------------"
          )
        end
        return true
      else
        return false
      end
    end

    def SettingsXinetdPure(server_args)
      server_args = deep_copy(server_args)
      option = ""
      Builtins.y2milestone(
        "---------------boolean SettingsXinetdPure (list <string> server_args)-----------------"
      )
      Builtins.y2milestone(
        "----------------------------------------------------"
      )

      #bnc#597842 Yast2-ftp-server module losses the chroot everyone (chroot-local-user) setting
      #the problem appears to be that after vsftpd settings are parsed,
      #the correct values are overwritten by parsing the (meaningless)
      #settings for pure-ftpd.


      if @vsftpd_edit || Builtins.size(@pure_ftpd_xinet_conf) == 0
        Builtins.y2milestone(
          "skip SettingsXinetdPure() -> vsftpd is used or pure_ftpd_xinet_conf is empty"
        )
        return true
      end

      #ChrootEnable
      option = Builtins.find(@pure_ftpd_xinet_conf) { |opt| opt == "-A" }
      if option != nil
        Ops.set(@EDIT_SETTINGS, "ChrootEnable", "-A" == option ? "YES" : "NO")
      else
        Ops.set(@EDIT_SETTINGS, "ChrootEnable", "NO")
      end

      #VerboseLogging
      option = Builtins.find(@pure_ftpd_xinet_conf) { |opt| opt == "-d" }
      if option != nil
        Ops.set(@EDIT_SETTINGS, "VerboseLogging", "-d" == option ? "YES" : "NO")
      else
        Ops.set(@EDIT_SETTINGS, "VerboseLogging", "NO")
      end

      #AnonReadOnly
      option = Builtins.find(@pure_ftpd_xinet_conf) { |opt| opt == "-i" }
      if option != nil
        Ops.set(@EDIT_SETTINGS, "AnonReadOnly", "-i" == option ? "YES" : "NO")
      else
        Ops.set(@EDIT_SETTINGS, "AnonReadOnly", "YES")
      end

      #AnonCreatDirs
      option = Builtins.find(@pure_ftpd_xinet_conf) { |opt| opt == "-M" }
      if option != nil
        Ops.set(@EDIT_SETTINGS, "AnonCreatDirs", "-M" == option ? "YES" : "NO")
      else
        Ops.set(@EDIT_SETTINGS, "AnonCreatDirs", "NO")
      end

      #AntiWarez
      option = Builtins.find(@pure_ftpd_xinet_conf) { |opt| opt == "-s" }
      if option != nil
        Ops.set(@EDIT_SETTINGS, "AntiWarez", "-s" == option ? "YES" : "NO")
      else
        Ops.set(@EDIT_SETTINGS, "AntiWarez", "NO")
      end
      #AnonAuthen
      yes_no = ""
      authen = 0
      yes_no = nil != Builtins.find(@pure_ftpd_xinet_conf) { |opt| opt == "-e" } ? "YES" : "NO"
      if yes_no == "YES"
        authen = 0
      else
        authen = 1
      end
      yes_no = ""
      yes_no = nil != Builtins.find(@pure_ftpd_xinet_conf) { |opt| opt == "-E" } ? "YES" : "NO"
      authen = Ops.add(authen, 2) if yes_no == "YES"
      if authen == 0
        Ops.set(@EDIT_SETTINGS, "AnonAuthen", "0")
      else
        Ops.set(@EDIT_SETTINGS, "AnonAuthen", authen == 3 ? "2" : "1")
      end
      #numeric and string options


      #Umask
      option = Builtins.find(@pure_ftpd_xinet_conf) do |opt|
        Builtins.issubstring(opt, "-U")
      end
      option = Builtins.substring(Builtins.tostring(option), 2) if option != nil
      Ops.set(@EDIT_SETTINGS, "Umask", option != nil ? option : "")

      #SSL

      option = Builtins.find(@pure_ftpd_xinet_conf) do |opt|
        Builtins.issubstring(opt, "-Y")
      end
      option = Builtins.substring(Builtins.tostring(option), 2) if option != nil
      Ops.set(@EDIT_SETTINGS, "SSL", option != nil ? option : "1")

      #AnonMaxRate
      option = Builtins.find(@pure_ftpd_xinet_conf) do |opt|
        Builtins.issubstring(opt, "-t")
      end
      option = Builtins.substring(Builtins.tostring(option), 2) if option != nil
      Ops.set(@EDIT_SETTINGS, "AnonMaxRate", option != nil ? option : "0")

      #LocalMaxRate
      option = Builtins.find(@pure_ftpd_xinet_conf) do |opt|
        Builtins.issubstring(opt, "-T")
      end
      option = Builtins.substring(Builtins.tostring(option), 2) if option != nil
      Ops.set(@EDIT_SETTINGS, "LocalMaxRate", option != nil ? option : "0")

      #MaxClientsNumber
      option = Builtins.find(@pure_ftpd_xinet_conf) do |opt|
        Builtins.issubstring(opt, "-c")
      end
      option = Builtins.substring(Builtins.tostring(option), 2) if option != nil
      Ops.set(@EDIT_SETTINGS, "MaxClientsNumber", option != nil ? option : "10")

      #MaxClientsPerIP
      option = Builtins.find(@pure_ftpd_xinet_conf) do |opt|
        Builtins.issubstring(opt, "-C")
      end
      option = Builtins.substring(Builtins.tostring(option), 2) if option != nil
      Ops.set(@EDIT_SETTINGS, "MaxClientsPerIP", option != nil ? option : "3")

      #MaxIdleTime
      option = Builtins.find(@pure_ftpd_xinet_conf) do |opt|
        Builtins.issubstring(opt, "-I")
      end
      option = Builtins.substring(Builtins.tostring(option), 2) if option != nil
      Ops.set(@EDIT_SETTINGS, "MaxIdleTime", option != nil ? option : "15")

      #PasMinPort and PasMaxPort
      option = Builtins.find(@pure_ftpd_xinet_conf) do |opt|
        Builtins.issubstring(opt, "-p")
      end
      if option != nil
        option = Builtins.substring(Builtins.tostring(option), 2)
        option = Builtins.filterchars(option, "0123456789:")
      end
      if option != nil
        ports = []
        ports = Builtins.splitstring(option, ":")
        if Builtins.size(ports) == 2
          Ops.set(@EDIT_SETTINGS, "PasMinPort", Ops.get(ports, 0, ""))
          Ops.set(@EDIT_SETTINGS, "PasMaxPort", Ops.get(ports, 1, ""))
        else
          Ops.set(
            @EDIT_SETTINGS,
            "PasMinPort",
            Ops.get(@DEFAULT_CONFIG, "PasMinPort")
          )
          Ops.set(
            @EDIT_SETTINGS,
            "PasMaxPort",
            Ops.get(@DEFAULT_CONFIG, "PasMaxPort")
          )
        end
      else
        Ops.set(
          @EDIT_SETTINGS,
          "PasMinPort",
          Ops.get(@DEFAULT_CONFIG, "PasMinPort")
        )
        Ops.set(
          @EDIT_SETTINGS,
          "PasMaxPort",
          Ops.get(@DEFAULT_CONFIG, "PasMaxPort")
        )
      end


      #VirtualUser
      option = Builtins.find(@pure_ftpd_xinet_conf) do |opt|
        Builtins.issubstring(opt, "-l")
      end
      option = Builtins.substring(Builtins.tostring(option), 2) if option != nil
      if option != nil
        if -1 != Builtins.find(option, "puredb")
          Ops.set(@EDIT_SETTINGS, "VirtualUser", "YES")
        end
      else
        Ops.set(@EDIT_SETTINGS, "VirtualUser", "NO")
      end


      true
    end


    def PureSettingsForXinetd
      result = ""

      result = "-A " if Ops.get(@EDIT_SETTINGS, "ChrootEnable") == "YES"

      if Ops.get(@EDIT_SETTINGS, "VerboseLogging") == "YES"
        result = Ops.add(result, "-d ")
      end

      if Ops.get(@EDIT_SETTINGS, "AnonReadOnly") == "YES"
        result = Ops.add(result, "-i ")
      end

      if Ops.get(@EDIT_SETTINGS, "AnonCreatDirs") == "YES"
        result = Ops.add(result, "-M ")
      end

      if Ops.get(@EDIT_SETTINGS, "AntiWarez") == "YES"
        result = Ops.add(result, "-s ")
      end

      #anonymous only
      if Ops.get(@EDIT_SETTINGS, "AnonAuthen") == "0"
        result = Ops.add(result, "-e ")
      end

      #local only
      if Ops.get(@EDIT_SETTINGS, "AnonAuthen") == "1"
        result = Ops.add(result, "-E ")
      end

      #both
      if Ops.get(@EDIT_SETTINGS, "AnonAuthen") == "2"
        result = Ops.add(result, "-e -E ")
      end

      if Ops.get(@EDIT_SETTINGS, "Umask") != ""
        result = Ops.add(
          Ops.add(result, "-U "),
          Ops.get(@EDIT_SETTINGS, "Umask")
        )
      end

      #SSL
      if Ops.get(@EDIT_SETTINGS, "SSL") != ""
        result = Ops.add(
          Ops.add(Ops.add(result, "-Y"), Ops.get(@EDIT_SETTINGS, "SSL")),
          " "
        )
      end

      #anonymous rate
      if Ops.get(@EDIT_SETTINGS, "AnonMaxRate") != "0"
        result = Ops.add(
          Ops.add(Ops.add(result, "-t"), Ops.get(@EDIT_SETTINGS, "AnonMaxRate")),
          " "
        )
      end

      #local rate
      if Ops.get(@EDIT_SETTINGS, "LocalMaxRate") != "0"
        result = Ops.add(
          Ops.add(
            Ops.add(result, "-T"),
            Ops.get(@EDIT_SETTINGS, "LocalMaxRate")
          ),
          " "
        )
      end

      #max clients
      if Ops.get(@EDIT_SETTINGS, "MaxClientsNumber") != ""
        result = Ops.add(
          Ops.add(
            Ops.add(result, "-c"),
            Ops.get(@EDIT_SETTINGS, "MaxClientsNumber")
          ),
          " "
        )
      end

      #max clients per IP
      if Ops.get(@EDIT_SETTINGS, "MaxClientsPerIP") != ""
        result = Ops.add(
          Ops.add(
            Ops.add(result, "-C"),
            Ops.get(@EDIT_SETTINGS, "MaxClientsPerIP")
          ),
          " "
        )
      end

      #max idle time
      if Ops.get(@EDIT_SETTINGS, "MaxIdleTime") != ""
        result = Ops.add(
          Ops.add(Ops.add(result, "-I"), Ops.get(@EDIT_SETTINGS, "MaxIdleTime")),
          " "
        )
      end

      #port range for passive connections
      result = Ops.add(
        Ops.add(
          Ops.add(Ops.add(result, "-p"), Ops.get(@EDIT_SETTINGS, "PasMinPort")),
          ":"
        ),
        Ops.get(@EDIT_SETTINGS, "PasMaxPort")
      )

      Builtins.y2milestone(
        "[ftp-server] (PureSettingsForXinetd) options for xinetd from pure-ftpd settings: %1",
        result
      )
      result
    end


    def InitStartViaXinetd
      xinetd_running = false
      if IdFTPXinetd()
        if Service.Status("xinetd") == 0
          xinetd_running = true
          Ops.set(@EDIT_SETTINGS, "StartXinetd", "YES")
        end
        if @vsftpd_edit
          if Ops.get(Inetd.netd_conf, [@vsftpd_xined_id, "enabled"]) == true
            Ops.set(@EDIT_SETTINGS, "StartDaemon", "2")
            @vsftp_xinetd_running = true if xinetd_running
            return true
          end
        else
          if Ops.get(Inetd.netd_conf, [@pureftpd_xined_id, "enabled"]) == true
            Ops.set(@EDIT_SETTINGS, "StartDaemon", "2")
            @pure_ftp_xinetd_running = true if xinetd_running
            return true
          end
        end #end of if (IdFTPXined ())]
      else
        return false
      end

      nil
    end


    def WriteStartViaXinetd(startxinetd, push_star_now)
      pure_options = ""
      result = false

      if Ops.get(@EDIT_SETTINGS, "StartDaemon") == "2" && !@stop_daemon_xinetd
        if @vsftpd_edit
          Ops.set(Inetd.netd_conf, [@vsftpd_xined_id, "enabled"], true)
          Ops.set(Inetd.netd_conf, [@pureftpd_xined_id, "enabled"], false)
          @pure_ftp_xinetd_running = false
        else
          Ops.set(Inetd.netd_conf, [@pureftpd_xined_id, "enabled"], true)
          Ops.set(Inetd.netd_conf, [@vsftpd_xined_id, "enabled"], false)
          @vsftp_xinetd_running = false
          if push_star_now
            pure_options = PureSettingsForXinetd()
          else
            options = Convert.to_map(
              SCR.Execute(
                path(".target.bash_output"),
                "/usr/sbin/pure-config-args /etc/pure-ftpd/pure-ftpd.conf"
              )
            )
            if Ops.get(options, "exit") == 0
              pure_options = Ops.get_string(options, "stdout")
            else
              return false
            end
          end
          Ops.set(
            Inetd.netd_conf,
            [@pureftpd_xined_id, "server"],
            "/usr/sbin/pure-ftpd"
          )
          Ops.set(
            Inetd.netd_conf,
            [@pureftpd_xined_id, "server_args"],
            pure_options
          )
        end

        Inetd.netd_status = 0 if startxinetd #start xinetd if not running else reload
      else
        Inetd.netd_status = 0
        Ops.set(Inetd.netd_conf, [@pureftpd_xined_id, "enabled"], false)
        Ops.set(Inetd.netd_conf, [@vsftpd_xined_id, "enabled"], false)
        @vsftp_xinetd_running = false
        @pure_ftp_xinetd_running = false
      end #end of else [ if (FtpServer::EDIT_SETTINGS["StartDaemon"]:nil == "2")]

      Ops.set(Inetd.netd_conf, [@pureftpd_xined_id, "changed"], true)
      Ops.set(Inetd.netd_conf, [@vsftpd_xined_id, "changed"], true)
      # writing changes into xinetd
      status_progress = Progress.set(false)
      result = Inetd.Write
      Progress.set(status_progress)

      result
    end

    # Returns boundaries defined by PassivePortRange.
    #
    # two delimiters are allowed in port range: colon and space. See bnc#782386
    # numbers in range can be separated by at least one whitespace or just one colon.
    def GetPassivePortRangeBoundaries
      # this function is specific for pure-ftpd config.
      return nil if @vsftpd_edit

      port_range = Builtins.regexpsub(
        Ops.get(@PURE_SETTINGS, "PassivePortRange"),
        "^([0-9]*)(\\s+|:)([0-9]*)$",
        "\\1:\\3"
      )

      port_range != nil ? Builtins.splitstring(port_range, ":") : nil
    end

    # Function return init value for UI widgets
    # and prepare internal data structure for writing
    # to config file
    # Example: ValueUI("ChrootEnabled") => "yes"/"no"

    def ValueUI(key, write)
      ports = []
      authentic = 0
      yes_no = ""
      case key
        when "ChrootEnable"
          if @vsftpd_edit
            if write
              Ops.set(
                @VS_SETTINGS,
                "chroot_local_user",
                Ops.get(@EDIT_SETTINGS, "ChrootEnable")
              )
            else
              return Builtins.haskey(@VS_SETTINGS, "chroot_local_user") ?
                Builtins.toupper(Ops.get(@VS_SETTINGS, "chroot_local_user")) :
                Ops.get(@DEFAULT_CONFIG, "ChrootEnable")
            end
          else
            if write
              Ops.set(
                @PURE_SETTINGS,
                "ChrootEveryone",
                Ops.get(@EDIT_SETTINGS, "ChrootEnable")
              )
            else
              return Builtins.haskey(@PURE_SETTINGS, "ChrootEveryone") ?
                Builtins.toupper(Ops.get(@PURE_SETTINGS, "ChrootEveryone")) :
                Ops.get(@DEFAULT_CONFIG, "ChrootEnable")
            end
          end
        when "VerboseLogging"
          if @vsftpd_edit
            if write
              Ops.set(
                @VS_SETTINGS,
                "log_ftp_protocol",
                Ops.get(@EDIT_SETTINGS, "VerboseLogging")
              )
              Ops.set(
                @VS_SETTINGS,
                "syslog_enable",
                Ops.get(@EDIT_SETTINGS, "VerboseLogging")
              )
            else
              return Builtins.haskey(@VS_SETTINGS, "log_ftp_protocol") ?
                Builtins.toupper(Ops.get(@VS_SETTINGS, "log_ftp_protocol")) :
                Ops.get(@DEFAULT_CONFIG, "VerboseLogging")
            end
          else
            if write
              Ops.set(
                @PURE_SETTINGS,
                "VerboseLog",
                Ops.get(@EDIT_SETTINGS, "VerboseLogging")
              )
            else
              return Builtins.haskey(@PURE_SETTINGS, "VerboseLog") ?
                Builtins.toupper(Ops.get(@PURE_SETTINGS, "VerboseLog")) :
                Ops.get(@DEFAULT_CONFIG, "VerboseLogging")
            end
          end
        when "FtpDirLocal"
          if @vsftpd_edit
            if write
              if Ops.get(@EDIT_SETTINGS, "FtpDirLocal") != ""
                Ops.set(
                  @VS_SETTINGS,
                  "local_root",
                  Ops.get(@EDIT_SETTINGS, "FtpDirLocal")
                )
              else
                Ops.set(@VS_SETTINGS, "local_root", nil)
              end
            else
              return Builtins.haskey(@VS_SETTINGS, "local_root") ?
                Ops.get(@VS_SETTINGS, "local_root") :
                Ops.get(@DEFAULT_CONFIG, "FtpDirLocal")
            end
          else
            if !write
              return Ops.get(@DEFAULT_CONFIG, "FtpDirLocal")
            else
              return ""
            end
          end
        when "FtpDirAnon"
          if @vsftpd_edit
            if write
              if Ops.get(@EDIT_SETTINGS, "FtpDirAnon") != ""
                Ops.set(
                  @VS_SETTINGS,
                  "anon_root",
                  Ops.get(@EDIT_SETTINGS, "FtpDirAnon")
                )
              else
                Ops.set(@VS_SETTINGS, "anon_root", nil)
              end
            else
              return Builtins.haskey(@VS_SETTINGS, "anon_root") ?
                Ops.get(@VS_SETTINGS, "anon_root") :
                Ops.get(@DEFAULT_CONFIG, "FtpDirAnon")
            end
          else
            if !write
              # initialization this part will be done
              # in function ReadSettings () in FtpServer.ycp
              #
              return ""
            else
              # write option will be done
              # in function WriteSettings () in FtpServer.ycp
              #
              return ""
            end
          end
        when "UmaskAnon"
          if @vsftpd_edit
            if write
              if Ops.get(@EDIT_SETTINGS, "UmaskAnon") != ""
                Ops.set(
                  @VS_SETTINGS,
                  "anon_umask",
                  Ops.get(@EDIT_SETTINGS, "UmaskAnon")
                )
              else
                Ops.set(@VS_SETTINGS, "anon_umask", nil)
              end
            else
              return Builtins.haskey(@VS_SETTINGS, "anon_umask") ?
                Builtins.toupper(Ops.get(@VS_SETTINGS, "anon_umask")) :
                Ops.get(@DEFAULT_CONFIG, "UmaskAnon")
            end
          else
            if !write
              return Ops.get(@DEFAULT_CONFIG, "UmaskAnon")
            else
              return ""
            end
          end
        when "UmaskLocal"
          if @vsftpd_edit
            if write
              if Ops.get(@EDIT_SETTINGS, "UmaskLocal") != ""
                Ops.set(
                  @VS_SETTINGS,
                  "local_umask",
                  Ops.get(@EDIT_SETTINGS, "UmaskLocal")
                )
              else
                Ops.set(@VS_SETTINGS, "local_umask", nil)
              end
            else
              return Builtins.haskey(@VS_SETTINGS, "local_umask") ?
                Builtins.toupper(Ops.get(@VS_SETTINGS, "local_umask")) :
                Ops.get(@DEFAULT_CONFIG, "UmaskLocal")
            end
          else
            if !write
              return Ops.get(@DEFAULT_CONFIG, "UmaskLocal")
            else
              return ""
            end
          end
        when "Umask"
          if @vsftpd_edit
            if !write
              return Ops.get(@DEFAULT_CONFIG, "Umask")
            else
              return ""
            end
          else
            if write
              if Ops.get(@EDIT_SETTINGS, "Umask") != ""
                Ops.set(
                  @PURE_SETTINGS,
                  "Umask",
                  Ops.get(@EDIT_SETTINGS, "Umask")
                )
              else
                Ops.set(@PURE_SETTINGS, "Umask", nil)
              end
            else
              return Builtins.haskey(@PURE_SETTINGS, "Umask") ?
                Ops.get(@PURE_SETTINGS, "Umask") :
                Ops.get(@DEFAULT_CONFIG, "Umask")
            end
          end
        when "PasMinPort"
          if @vsftpd_edit
            if write
              if Ops.get(@EDIT_SETTINGS, "PasMinPort") != ""
                Ops.set(
                  @VS_SETTINGS,
                  "pasv_min_port",
                  Ops.get(@EDIT_SETTINGS, "PasMinPort")
                )
              else
                Ops.set(@VS_SETTINGS, "pasv_min_port", nil)
              end
            else
              return Builtins.haskey(@VS_SETTINGS, "pasv_min_port") ?
                Builtins.toupper(Ops.get(@VS_SETTINGS, "pasv_min_port")) :
                Ops.get(@DEFAULT_CONFIG, "PasMinPort")
            end
          else
            if write
              if Ops.get(@EDIT_SETTINGS, "PasMinPort") != "" &&
                  Ops.get(@EDIT_SETTINGS, "PasMaxPort") != "0"
                ports = Builtins.add(
                  ports,
                  Ops.get(@EDIT_SETTINGS, "PasMinPort")
                )
                ports = Builtins.add(
                  ports,
                  Ops.get(@EDIT_SETTINGS, "PasMaxPort")
                )
                if Builtins.size(ports) == 2
                  val = Ops.get(ports, 0)
                  val = Ops.add(val, ":")
                  val = Ops.add(val, Ops.get(ports, 1))
                  Ops.set(@PURE_SETTINGS, "PassivePortRange", val)
                end
              else
                Ops.set(@PURE_SETTINGS, "PassivePortRange", nil)
              end
            else
              if Builtins.haskey(@PURE_SETTINGS, "PassivePortRange")
                ports = GetPassivePortRangeBoundaries()
                return Ops.get(ports, 0, "") if Builtins.size(ports) == 2
              else
                return Ops.get(@DEFAULT_CONFIG, "PasMinPort")
              end
            end
          end
        when "PasMaxPort"
          if @vsftpd_edit
            if write
              if Ops.get(@EDIT_SETTINGS, "PasMaxPort") != "0"
                Ops.set(
                  @VS_SETTINGS,
                  "pasv_max_port",
                  Ops.get(@EDIT_SETTINGS, "PasMaxPort")
                )
              else
                Ops.set(@VS_SETTINGS, "pasv_max_port", nil)
                Ops.set(@VS_SETTINGS, "pasv_min_port", nil)
              end
            else
              return Builtins.haskey(@VS_SETTINGS, "pasv_max_port") ?
                Builtins.toupper(Ops.get(@VS_SETTINGS, "pasv_max_port")) :
                Ops.get(@DEFAULT_CONFIG, "PasMaxPort")
            end
          else
            if write
              return ""
            else
              if Builtins.haskey(@PURE_SETTINGS, "PassivePortRange")
                ports = GetPassivePortRangeBoundaries()
                return Ops.get(ports, 1, "") if Builtins.size(ports) == 2
              else
                return Ops.get(@DEFAULT_CONFIG, "PasMaxPort")
              end
            end
          end
        when "MaxIdleTime"
          if @vsftpd_edit
            min_sec = 0
            if write
              if Ops.get(@EDIT_SETTINGS, "MaxIdleTime") != "0"
                min_sec = Builtins.tointeger(
                  Ops.get(@EDIT_SETTINGS, "MaxIdleTime")
                )
                min_sec = Ops.multiply(min_sec, 60)
                Ops.set(
                  @VS_SETTINGS,
                  "idle_session_timeout",
                  Builtins.tostring(min_sec)
                )
              else
                Ops.set(@VS_SETTINGS, "idle_session_timeout", nil)
              end
            else
              if Builtins.haskey(@VS_SETTINGS, "idle_session_timeout")
                min_sec = Builtins.tointeger(
                  Ops.get(@VS_SETTINGS, "idle_session_timeout")
                )
                min_sec = Ops.divide(min_sec, 60)
                return Builtins.tostring(min_sec)
              else
                return Ops.get(@DEFAULT_CONFIG, "MaxIdleTime")
              end
            end
          else
            if write
              if Ops.get(@EDIT_SETTINGS, "MaxIdleTime") != "0"
                Ops.set(
                  @PURE_SETTINGS,
                  "MaxIdleTime",
                  Ops.get(@EDIT_SETTINGS, "MaxIdleTime")
                )
              else
                Ops.set(@PURE_SETTINGS, "MaxIdleTime", nil)
              end
            else
              return Builtins.haskey(@PURE_SETTINGS, "MaxIdleTime") ?
                Ops.get(@PURE_SETTINGS, "MaxIdleTime") :
                Ops.get(@DEFAULT_CONFIG, "MaxIdleTime")
            end
          end
        when "MaxClientsPerIP"
          if @vsftpd_edit
            if write
              if Ops.get(@EDIT_SETTINGS, "MaxClientsPerIP") != "0"
                Ops.set(
                  @VS_SETTINGS,
                  "max_per_ip",
                  Ops.get(@EDIT_SETTINGS, "MaxClientsPerIP")
                )
              else
                Ops.set(@VS_SETTINGS, "max_per_ip", nil)
              end
            else
              return Builtins.haskey(@VS_SETTINGS, "max_per_ip") ?
                Builtins.toupper(Ops.get(@VS_SETTINGS, "max_per_ip")) :
                Ops.get(@DEFAULT_CONFIG, "MaxClientsPerIP")
            end
          else
            if write
              if Ops.get(@EDIT_SETTINGS, "MaxClientsPerIP") != "0"
                Ops.set(
                  @PURE_SETTINGS,
                  "MaxClientsPerIP",
                  Ops.get(@EDIT_SETTINGS, "MaxClientsPerIP")
                )
              else
                Ops.set(@PURE_SETTINGS, "MaxClientsPerIP", nil)
              end
            else
              return Builtins.haskey(@PURE_SETTINGS, "MaxClientsPerIP") ?
                Ops.get(@PURE_SETTINGS, "MaxClientsPerIP") :
                Ops.get(@DEFAULT_CONFIG, "MaxClientsPerIP")
            end
          end
        when "MaxClientsNumber"
          if @vsftpd_edit
            if write
              if Ops.get(@EDIT_SETTINGS, "MaxClientsNumber") != "0"
                Ops.set(
                  @VS_SETTINGS,
                  "max_clients",
                  Ops.get(@EDIT_SETTINGS, "MaxClientsNumber")
                )
              else
                Ops.set(@VS_SETTINGS, "max_clients", nil)
              end
            else
              return Builtins.haskey(@VS_SETTINGS, "max_clients") ?
                Builtins.toupper(Ops.get(@VS_SETTINGS, "max_clients")) :
                Ops.get(@DEFAULT_CONFIG, "MaxClientsNumber")
            end
          else
            if write
              if Ops.get(@EDIT_SETTINGS, "MaxClientsNumber") != "0"
                Ops.set(
                  @PURE_SETTINGS,
                  "MaxClientsNumber",
                  Ops.get(@EDIT_SETTINGS, "MaxClientsNumber")
                )
              else
                Ops.set(@PURE_SETTINGS, "MaxClientsNumber", nil)
              end
            else
              return Builtins.haskey(@PURE_SETTINGS, "MaxClientsNumber") ?
                Ops.get(@PURE_SETTINGS, "MaxClientsNumber") :
                Ops.get(@DEFAULT_CONFIG, "MaxClientsNumber")
            end
          end
        when "LocalMaxRate"
          if @vsftpd_edit
            transfer = 0
            if write
              if Ops.get(@EDIT_SETTINGS, "LocalMaxRate") != "0"
                transfer = Ops.multiply(
                  Builtins.tointeger(Ops.get(@EDIT_SETTINGS, "LocalMaxRate")),
                  1024
                )
                Ops.set(
                  @VS_SETTINGS,
                  "local_max_rate",
                  Builtins.tostring(transfer)
                )
              else
                Ops.set(@VS_SETTINGS, "local_max_rate", nil)
              end
            else
              if Builtins.haskey(@VS_SETTINGS, "local_max_rate")
                transfer = Ops.divide(
                  Builtins.tointeger(Ops.get(@VS_SETTINGS, "local_max_rate")),
                  1024
                )
                return Builtins.tostring(transfer)
              else
                return Ops.get(@DEFAULT_CONFIG, "LocalMaxRate")
              end
            end
          else
            if write
              if Ops.get(@EDIT_SETTINGS, "LocalMaxRate") != "0"
                Ops.set(
                  @PURE_SETTINGS,
                  "UserBandwidth",
                  Ops.get(@EDIT_SETTINGS, "LocalMaxRate")
                )
              else
                Ops.set(@PURE_SETTINGS, "UserBandwidth", nil)
              end
            else
              return Builtins.haskey(@PURE_SETTINGS, "UserBandwidth") ?
                Ops.get(@PURE_SETTINGS, "UserBandwidth") :
                Ops.get(@DEFAULT_CONFIG, "LocalMaxRate")
            end
          end
        when "AnonMaxRate"
          if @vsftpd_edit
            transfer = 0
            if write
              if Ops.get(@EDIT_SETTINGS, "AnonMaxRate") != "0"
                transfer = Ops.multiply(
                  Builtins.tointeger(Ops.get(@EDIT_SETTINGS, "AnonMaxRate")),
                  1024
                )
                Ops.set(
                  @VS_SETTINGS,
                  "anon_max_rate",
                  Builtins.tostring(transfer)
                )
              else
                Ops.set(@VS_SETTINGS, "anon_max_rate", nil)
              end
            else
              if Builtins.haskey(@VS_SETTINGS, "anon_max_rate")
                transfer = Ops.divide(
                  Builtins.tointeger(Ops.get(@VS_SETTINGS, "anon_max_rate")),
                  1024
                )
                return Builtins.tostring(transfer)
              else
                return Ops.get(@DEFAULT_CONFIG, "AnonMaxRate")
              end
            end
          else
            if write
              if Ops.get(@EDIT_SETTINGS, "AnonMaxRate") != "0"
                Ops.set(
                  @PURE_SETTINGS,
                  "AnonymousBandwidth",
                  Ops.get(@EDIT_SETTINGS, "AnonMaxRate")
                )
              else
                Ops.set(@PURE_SETTINGS, "AnonymousBandwidth", nil)
              end
            else
              return Builtins.haskey(@PURE_SETTINGS, "AnonymousBandwidth") ?
                Ops.get(@PURE_SETTINGS, "AnonymousBandwidth") :
                Ops.get(@DEFAULT_CONFIG, "AnonMaxRate")
            end
          end
        when "AnonAuthen"
          @authen = 0
          if @vsftpd_edit
            if write
              val = Ops.get(@EDIT_SETTINGS, "AnonAuthen")
              if val == "0"
                Ops.set(@VS_SETTINGS, "anonymous_enable", "YES")
                Ops.set(@VS_SETTINGS, "local_enable", "NO")
              elsif val == "1"
                Ops.set(@VS_SETTINGS, "anonymous_enable", "NO")
                Ops.set(@VS_SETTINGS, "local_enable", "YES")
              else
                Ops.set(@VS_SETTINGS, "anonymous_enable", "YES")
                Ops.set(@VS_SETTINGS, "local_enable", "YES")
              end
            else
              yes_no = ""
              if Builtins.haskey(@VS_SETTINGS, "anonymous_enable")
                yes_no = Builtins.toupper(
                  Ops.get(@VS_SETTINGS, "anonymous_enable")
                )
              else
                yes_no = "YES"
              end
              if yes_no == "YES"
                @authen = 0
              else
                @authen = 1
              end
              if Builtins.haskey(@VS_SETTINGS, "local_enable")
                yes_no = Builtins.toupper(Ops.get(@VS_SETTINGS, "local_enable"))
              else
                yes_no = "NO"
              end
              if yes_no == "YES"
                @authen = Ops.add(@authen, 2)
              else
                @authen = Ops.add(@authen, 0)
              end
              if @authen == 0
                return "0"
              else
                return @authen == 3 ? "1" : "2"
              end
            end
          else
            if write
              val = Ops.get(@EDIT_SETTINGS, "AnonAuthen")
              if val == "0"
                Ops.set(@PURE_SETTINGS, "AnonymousOnly", "YES")
                Ops.set(@PURE_SETTINGS, "NoAnonymous", "NO")
              elsif val == "1"
                Ops.set(@PURE_SETTINGS, "AnonymousOnly", "NO")
                Ops.set(@PURE_SETTINGS, "NoAnonymous", "YES")
              else
                Ops.set(@PURE_SETTINGS, "AnonymousOnly", "NO")
                Ops.set(@PURE_SETTINGS, "NoAnonymous", "NO")
              end
            else
              yes_no = ""
              if Builtins.haskey(@PURE_SETTINGS, "AnonymousOnly")
                yes_no = Builtins.toupper(
                  Ops.get(@PURE_SETTINGS, "AnonymousOnly")
                )
              end
              if yes_no == "YES"
                @authen = 0
              else
                @authen = 1
              end
              yes_no = ""
              if Builtins.haskey(@PURE_SETTINGS, "NoAnonymous")
                yes_no2 = Builtins.toupper(
                  Ops.get(@PURE_SETTINGS, "NoAnonymous")
                )
              end
              @authen = Ops.add(@authen, 2) if yes_no == "YES"
              if @authen == 0
                return "0"
              else
                return @authen == 3 ? "2" : "1"
              end
            end
          end
        when "AnonReadOnly"
          if @vsftpd_edit
            if write
              yes_no = Ops.get(@EDIT_SETTINGS, "AnonReadOnly")
              if yes_no == "YES"
                Ops.set(@VS_SETTINGS, "anon_upload_enable", "NO")
              else
                Ops.set(@VS_SETTINGS, "anon_upload_enable", "YES")
              end
            else
              if Builtins.haskey(@VS_SETTINGS, "anon_upload_enable")
                yes_no = Builtins.toupper(
                  Ops.get(@VS_SETTINGS, "anon_upload_enable")
                )
                return yes_no == "YES" ? "NO" : "YES"
              else
                return Ops.get(@DEFAULT_CONFIG, "AnonReadOnly")
              end
            end
          else
            if write
              Ops.set(
                @PURE_SETTINGS,
                "AnonymousCantUpload",
                Ops.get(@EDIT_SETTINGS, "AnonReadOnly")
              )
            else
              return Builtins.haskey(@PURE_SETTINGS, "AnonymousCantUpload") ?
                Builtins.toupper(Ops.get(@PURE_SETTINGS, "AnonymousCantUpload")) :
                Ops.get(@DEFAULT_CONFIG, "AnonReadOnly")
            end
          end
        when "AnonCreatDirs"
          if @vsftpd_edit
            if write
              Ops.set(
                @VS_SETTINGS,
                "anon_mkdir_write_enable",
                Ops.get(@EDIT_SETTINGS, "AnonCreatDirs")
              )
            else
              return Builtins.haskey(@VS_SETTINGS, "anon_mkdir_write_enable") ?
                Builtins.toupper(
                  Ops.get(@VS_SETTINGS, "anon_mkdir_write_enable")
                ) :
                Ops.get(@DEFAULT_CONFIG, "AnonCreatDirs")
            end
          else
            if write
              Ops.set(
                @PURE_SETTINGS,
                "AnonymousCanCreateDirs",
                Ops.get(@EDIT_SETTINGS, "AnonCreatDirs")
              )
            else
              return Builtins.haskey(@PURE_SETTINGS, "AnonymousCanCreateDirs") ?
                Builtins.toupper(
                  Ops.get(@PURE_SETTINGS, "AnonymousCanCreateDirs")
                ) :
                Ops.get(@DEFAULT_CONFIG, "AnonCreatDirs")
            end
          end
        when "EnableUpload"
          if @vsftpd_edit
            if write
              if Ops.get(@EDIT_SETTINGS, "EnableUpload") != ""
                Ops.set(
                  @VS_SETTINGS,
                  "write_enable",
                  Ops.get(@EDIT_SETTINGS, "EnableUpload")
                )
              else
                Ops.set(@VS_SETTINGS, "write_enable", nil)
              end
            else
              return Builtins.haskey(@VS_SETTINGS, "write_enable") ?
                Ops.get(@VS_SETTINGS, "write_enable") :
                Ops.get(@DEFAULT_CONFIG, "EnableUpload")
            end
          else
            if !write
              return Ops.get(@DEFAULT_CONFIG, "EnableUpload")
            else
              return ""
            end
          end
        when "Banner"
          if @vsftpd_edit
            if write
              if Ops.get(@EDIT_SETTINGS, "Banner") != ""
                Ops.set(
                  @VS_SETTINGS,
                  "ftpd_banner",
                  Ops.get(@EDIT_SETTINGS, "Banner")
                )
              else
                Ops.set(@VS_SETTINGS, "ftpd_banner", nil)
              end
            else
              return Builtins.haskey(@VS_SETTINGS, "ftpd_banner") ?
                Ops.get(@VS_SETTINGS, "ftpd_banner") :
                Ops.get(@DEFAULT_CONFIG, "Banner")
            end
          else
            if !write
              return Ops.get(@DEFAULT_CONFIG, "Banner")
            else
              return ""
            end
          end
        when "SSLEnable"
          if @vsftpd_edit
            if write
              if Ops.get(@EDIT_SETTINGS, "SSLEnable") != ""
                Ops.set(
                  @VS_SETTINGS,
                  "ssl_enable",
                  Ops.get(@EDIT_SETTINGS, "SSLEnable")
                )
              else
                Ops.set(@VS_SETTINGS, "ssl_enable", "NO")
              end
            else
              return Builtins.haskey(@VS_SETTINGS, "ssl_enable") ?
                Builtins.toupper(Ops.get(@VS_SETTINGS, "ssl_enable")) :
                Ops.get(@DEFAULT_CONFIG, "SSLEnable")
            end
          else
            if !write
              return Ops.get(@DEFAULT_CONFIG, "SSLEnable")
            else
              return ""
            end
          end
        when "CertFile"
          if @vsftpd_edit
            if write
              if Ops.get(@EDIT_SETTINGS, "CertFile") != ""
                Ops.set(
                  @VS_SETTINGS,
                  "dsa_cert_file",
                  Ops.get(@EDIT_SETTINGS, "CertFile")
                )
              else
                Ops.set(@VS_SETTINGS, "dsa_cert_file", nil)
              end
            else
              return Builtins.haskey(@VS_SETTINGS, "dsa_cert_file") ?
                Ops.get(@VS_SETTINGS, "dsa_cert_file") :
                Ops.get(@DEFAULT_CONFIG, "CertFile")
            end
          else
            if !write
              return Ops.get(@DEFAULT_CONFIG, "CertFile")
            else
              return ""
            end
          end
        when "PassiveMode"
          if @vsftpd_edit
            if write
              if Ops.get(@EDIT_SETTINGS, "PassiveMode") != ""
                Ops.set(
                  @VS_SETTINGS,
                  "pasv_enable",
                  Ops.get(@EDIT_SETTINGS, "PassiveMode")
                )
              else
                Ops.set(@VS_SETTINGS, "pasv_enable", "NO")
              end
            else
              return Builtins.haskey(@VS_SETTINGS, "pasv_enable") ?
                Builtins.toupper(Ops.get(@VS_SETTINGS, "pasv_enable")) :
                Ops.get(@DEFAULT_CONFIG, "PassiveMode")
            end
          else
            if !write
              return Ops.get(@DEFAULT_CONFIG, "PassiveMode")
            else
              return ""
            end
          end
        when "TLS"
          if @vsftpd_edit
            if write
              Ops.set(@VS_SETTINGS, "ssl_tlsv1", Ops.get(@EDIT_SETTINGS, "TLS"))
            else
              return Builtins.haskey(@VS_SETTINGS, "ssl_tlsv1") ?
                Builtins.toupper(Ops.get(@VS_SETTINGS, "ssl_tlsv1")) :
                Ops.get(@DEFAULT_CONFIG, "TLS")
            end
          else
            if !write
              return Ops.get(@DEFAULT_CONFIG, "TLS")
            else
              return ""
            end
          end
        when "SSLv2"
          if @vsftpd_edit
            if write
              Ops.set(
                @VS_SETTINGS,
                "ssl_sslv2",
                Ops.get(@EDIT_SETTINGS, "SSLv2")
              )
            else
              return Builtins.haskey(@VS_SETTINGS, "ssl_sslv2") ?
                Builtins.toupper(Ops.get(@VS_SETTINGS, "ssl_sslv2")) :
                Ops.get(@DEFAULT_CONFIG, "SSLv2")
            end
          else
            if !write
              return Ops.get(@DEFAULT_CONFIG, "SSLv2")
            else
              return ""
            end
          end
        when "SSLv3"
          if @vsftpd_edit
            if write
              Ops.set(
                @VS_SETTINGS,
                "ssl_sslv3",
                Ops.get(@EDIT_SETTINGS, "SSLv3")
              )
            else
              return Builtins.haskey(@VS_SETTINGS, "ssl_sslv3") ?
                Builtins.toupper(Ops.get(@VS_SETTINGS, "ssl_sslv3")) :
                Ops.get(@DEFAULT_CONFIG, "SSLv3")
            end
          else
            if !write
              return Ops.get(@DEFAULT_CONFIG, "SSLv3")
            else
              return ""
            end
          end
        when "FTPUser"
          if @vsftpd_edit
            if write
              return ""
            else
              return Builtins.haskey(@VS_SETTINGS, "ftp_username") ?
                Ops.get(@VS_SETTINGS, "ftp_username") :
                Ops.get(@DEFAULT_CONFIG, "FTPUser")
            end
          else
            if !write
              return Ops.get(@DEFAULT_CONFIG, "FTPUser")
            else
              return ""
            end
          end
        when "GuestUser"
          if @vsftpd_edit
            if write
              return ""
            else
              if Builtins.haskey(@VS_SETTINGS, "guest_username") &&
                  Builtins.haskey(@VS_SETTINGS, "guest_enable")
                yes_no = Builtins.toupper(Ops.get(@VS_SETTINGS, "guest_enable"))
                if yes_no == "YES"
                  return Ops.get(@VS_SETTINGS, "guest_username")
                else
                  return Ops.get(@DEFAULT_CONFIG, "GuestUser")
                end
              else
                return Ops.get(@DEFAULT_CONFIG, "GuestUser")
              end
            end
          else
            if !write
              return Ops.get(@DEFAULT_CONFIG, "GuestUser")
            else
              return ""
            end
          end
        when "AntiWarez"
          if @vsftpd_edit
            if !write
              return Ops.get(@DEFAULT_CONFIG, "AntiWarez")
            else
              return ""
            end
          else
            if write
              Ops.set(
                @PURE_SETTINGS,
                "AntiWarez",
                Ops.get(@EDIT_SETTINGS, "AntiWarez")
              )
            else
              return Builtins.haskey(@PURE_SETTINGS, "AntiWarez") ?
                Builtins.toupper(Ops.get(@PURE_SETTINGS, "AntiWarez")) :
                Ops.get(@DEFAULT_CONFIG, "AntiWarez")
            end
          end
        when "SSL"
          if @vsftpd_edit
            if !write
              return Ops.get(@DEFAULT_CONFIG, "SSL")
            else
              return ""
            end
          else
            if write
              Ops.set(@PURE_SETTINGS, "TLS", Ops.get(@EDIT_SETTINGS, "SSL"))
            else
              return Builtins.haskey(@PURE_SETTINGS, "TLS") ?
                Ops.get(@PURE_SETTINGS, "TLS") :
                Ops.get(@DEFAULT_CONFIG, "SSL")
            end
          end
        when "VirtualUser"
          if @vsftpd_edit
            if !write
              return Ops.get(@DEFAULT_CONFIG, "VirtualUser")
            else
              return ""
            end
          else
            if !write
              if Builtins.haskey(@PURE_SETTINGS, "PureDB")
                return "YES"
              else
                return Ops.get(@DEFAULT_CONFIG, "VirtualUser")
              end
            end
          end
        when "StartXinetd"
          @result = false
          if write
            if Ops.get(@EDIT_SETTINGS, "StartDaemon") == "2"
              if Ops.get(@EDIT_SETTINGS, "StartXinetd") == "YES"
                @start_xinetd = true
                Service.Disable("vsftpd") if Service.Enabled("vsftpd")
                Service.Disable("pure-ftpd") if Service.Enabled("pure-ftpd")
                if @vsftpd_edit
                  Ops.set(@VS_SETTINGS, "listen", nil)
                  Ops.set(@VS_SETTINGS, "listen_ipv6", nil)
                else
                  Ops.set(@PURE_SETTINGS, "Daemonize", "NO")
                end
              end
            else
              if Ops.get(@EDIT_SETTINGS, "StartDaemon") == "1"
                if @vsftpd_edit
                  Service.Disable("pure-ftpd")
                  Service.Enable("vsftpd")
                else
                  Service.Disable("vsftpd")
                  Service.Enable("pure-ftpd")
                end
                if @vsftpd_edit
                  Ops.set(@VS_SETTINGS, "listen", "YES")
                  Ops.set(@VS_SETTINGS, "listen_ipv6", nil)
                else
                  Ops.set(@PURE_SETTINGS, "Daemonize", "YES")
                end
              else
                Service.Disable("vsftpd")
                Service.Disable("pure-ftpd")
                if @vsftpd_edit
                  Ops.set(@VS_SETTINGS, "listen", "YES")
                  Ops.set(@VS_SETTINGS, "listen_ipv6", nil)
                else
                  Ops.set(@PURE_SETTINGS, "Daemonize", "YES")
                end
              end
              @start_xinetd = false
            end 
            #FtpServer::EDIT_SETTINGS = remove(FtpServer::EDIT_SETTINGS, "StartXinetd");
          else
            Ops.set(@EDIT_SETTINGS, "StartDaemon", "0")
            @result = InitStartViaXinetd()
            if !@result
              if Service.Enabled("vsftpd") && @vsftpd_edit
                Ops.set(@EDIT_SETTINGS, "StartDaemon", "1")
              end
              if Service.Enabled("pure-ftpd") && !@vsftpd_edit
                Ops.set(@EDIT_SETTINGS, "StartDaemon", "1")
              end
            end
            if @result && Ops.get(@EDIT_SETTINGS, "StartDaemon") == "2"
              if Service.Status("xinetd") == 0
                SettingsXinetdPure(@pure_ftpd_xinet_conf)
              end
            end
            return Service.Status("xinetd") == 0 ? "YES" : "NO"
          end
        else
          Builtins.y2milestone(
            "[ftp-server] ValueUI(string key): unknown parameter %1",
            key
          )
          return ""
      end

      nil
    end
  end
end
