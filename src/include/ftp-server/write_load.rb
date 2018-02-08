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
    def initialize_ftp_server_write_load(_include_target)
      textdomain "ftp-server"

      Yast.import "Popup"
      Yast.import "Progress"
      Yast.import "Service"
      Yast.import "SystemdService"
      Yast.import "SystemdSocket"
    end

    def start_via_socket?
      socket = SystemdSocket.find("vsftpd")
      return false unless socket

      socket.enabled?
    end


    def WriteStartViaSocket(start)
      socket = SystemdSocket.find("vsftpd")
      return false unless socket

      if start
        socket.enable
        socket.start
      else
        socket.disable
        socket.stop
      end
      # stop service so socket can start new one with newly written configuration
      # or stop it completelly
      SystemdService.find!("vsftpd").stop

      true
    end

    # Convert between the UI (yast), and system (vsftpd, pure_ftpd) settings.
    #
    # The system settings are multiplexed by
    # {FtpServerClass#vsftpd_edit   vsftpd_edit}:
    # {FtpServerClass#VS_SETTINGS   VS_SETTINGS}   (for vsftpd_edit == true) or
    # {FtpServerClass#PURE_SETTINGS PURE_SETTINGS} (for vsftpd_edit == false).
    #
    # @param [String] key
    #  in the {FtpServerClass#EDIT_SETTINGS EDIT_SETTINGS} vocabulary
    # @param write
    #  - true: write to system settings from UI settings
    #                ({FtpServerClass#EDIT_SETTINGS EDIT_SETTINGS})
    #  - false: read the UI settings from the system settings
    # @return [String] the UI value (for read) or nil (for write)
    def ValueUI(key, write)
      case key
        when "ChrootEnable"
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
        when "VerboseLogging"
          if write
            @VS_SETTINGS["log_ftp_protocol"] = @EDIT_SETTINGS["VerboseLogging"]
            @VS_SETTINGS["xferlog_enable"] = @EDIT_SETTINGS["VerboseLogging"]
          else
            return (@VS_SETTINGS["log_ftp_protocol"] || @DEFAULT_CONFIG["log_ftp_protocol"]).upcase
          end
        when "FtpDirLocal"
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
        when "FtpDirAnon"
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
        when "UmaskAnon"
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
        when "UmaskLocal"
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
        when "Umask"
          if !write
            return Ops.get(@DEFAULT_CONFIG, "Umask")
          else
            return ""
          end
        when "PasMinPort"
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
        when "PasMaxPort"
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
        when "MaxIdleTime"
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
        when "MaxClientsPerIP"
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
        when "MaxClientsNumber"
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
        when "LocalMaxRate"
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
        when "AnonMaxRate"
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
        when "AnonAuthen"
          @authen = 0
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
        when "AnonReadOnly"
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
        when "AnonCreatDirs"
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
        when "EnableUpload"
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
        when "Banner"
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
        when "SSLEnable"
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
        when "CertFile"
          if write
            if Ops.get(@EDIT_SETTINGS, "CertFile") != ""
              Ops.set(
                @VS_SETTINGS,
                "rsa_cert_file",
                Ops.get(@EDIT_SETTINGS, "CertFile")
              )
            else
              Ops.set(@VS_SETTINGS, "rsa_cert_file", nil)
            end
          else
            return Builtins.haskey(@VS_SETTINGS, "rsa_cert_file") ?
              Ops.get(@VS_SETTINGS, "rsa_cert_file") :
              Ops.get(@DEFAULT_CONFIG, "CertFile")
          end
        when "PassiveMode"
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
        when "TLS"
          if write
            Ops.set(@VS_SETTINGS, "ssl_tlsv1", Ops.get(@EDIT_SETTINGS, "TLS"))
          else
            return Builtins.haskey(@VS_SETTINGS, "ssl_tlsv1") ?
              Builtins.toupper(Ops.get(@VS_SETTINGS, "ssl_tlsv1")) :
              Ops.get(@DEFAULT_CONFIG, "TLS")
          end
        when "SSLv2"
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
        when "SSLv3"
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
        when "FTPUser"
          if write
            return ""
          else
            return Builtins.haskey(@VS_SETTINGS, "ftp_username") ?
              Ops.get(@VS_SETTINGS, "ftp_username") :
              Ops.get(@DEFAULT_CONFIG, "FTPUser")
          end
        when "GuestUser"
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
        when "AntiWarez"
          if !write
            return Ops.get(@DEFAULT_CONFIG, "AntiWarez")
          else
            return ""
          end
        when "SSL"
          if !write
            return Ops.get(@DEFAULT_CONFIG, "SSL")
          else
            return ""
          end
        when "VirtualUser"
          if !write
            return Ops.get(@DEFAULT_CONFIG, "VirtualUser")
          else
            return ""
          end
        when "StartXinetd"
          # deprecated
          return "NO"
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
