# encoding: utf-8

# File:	include/ftp-server/helps.ycp
# Package:	Configuration of ftp-server
# Summary:	Help texts of all the dialogs
# Authors:	Jozef Uhliarik <juhliarik@suse.cz>
#
# $Id: helps.ycp 27914 2006-02-13 14:32:08Z juhliarik $
module Yast
  module FtpServerHelpsInclude
    def initialize_ftp_server_helps(_include_target)
      textdomain "ftp-server"

      # All helps are here
      @HELPS = {
        # Read dialog help 1/2
        "read"             => _(
          "<p><b><big>Initializing FTP Server Configuration</big></b><br>\n</p>\n"
        ) +
          # Read dialog help 2/2
          _(
            "<p><b><big>Aborting Initialization:</big></b><br>\nSafely abort the configuration utility by pressing <b>Abort</b> now.</p>\n"
          ),
        # Write dialog help 1/2
        "write"            => _(
          "<p><b><big>Saving FTP Server Configuration</big></b><br>\n</p>\n"
        ) +
          # Write dialog help 2/2
          _(
            "<p><b><big>Aborting Saving:</big></b><br>\n" \
              "Abort the save procedure by pressing <b>Abort</b>.\n" \
              "An additional dialog informs whether it is safe to do so.\n" \
              "</p>\n"
          ),
        #-----------================= GENERAL SCREEN =============----------
        #

        # general welcome message help 1/1
        "Banner"           => _(
          "<p><b>Welcome Message</b><br>\n" \
            "Specify the name of a file containing the\n" \
            "text to display when someone connects to the server.\n" \
            "</p>\n"
        ),
        # general chroot  help 1/1
        "ChrootEnable"     => _(
          "<p><b>Chroot</b><br>\n" \
            "When enabled, local users will be (by default) placed in a \n" \
            "chroot() jail in their home directory after login.\n" \
            "<b>Warning:</b> This option has security implications, \n" \
            "especially if users have upload permission\n" \
            "or shell access. Only enable Chroot if you know what you are doing.\n" \
            "</p>\n"
        ),
        # general logging  help 1/1
        "VerboseLogging"   => _(
          "<p><b>Verbose Logging</b><br>\n" \
            "When enabled, all FTP requests and responses are logged.\n" \
            "</p>\n"
        ),
        # general umask for anonymous  help
        "UmaskAnon"        => _(
          "<p><b>Umask for Anonymous:</b><br>\n" \
            "The value to which the umask for file creation is set for anonymous users. \n" \
            "If you want to specify octal values, remember the \"0\" prefix, otherwise \n" \
            "the value will be treated as a base 10 integer.\n" \
            "</p>\n"
        ),
        # general umask for authenticated users  help
        "UmaskLocal"       => _(
          "<p><b>Umask for Authenticated Users:</b><br>\n" \
            "The value to which the umask for file creation is set for authenticated users. \n" \
            "If you want to specify octal values, remember the \"0\" prefix, otherwise \n" \
            "the value will be treated as a base 10 integer.\n" \
            "</p>\n"
        ),
        # general FTP dir for anonymous help 1/1
        "FtpDirAnon"       => _(
          "<p><b>FTP Directory for Anonymous Users:</b><br>\n" \
            "Specify a directory which is used for FTP anonymous users. \n" \
            "Press <b>Browse</b> to select a directory from the local filesystem.\n" \
            "</p>\n"
        ),
        # general FTP dir for authenticated help 1/1
        "FtpDirLocal"      => _(
          "<p><b>FTP Directory for Authenticated Users:</b><br>\n" \
            "Specify a directory which is used for FTP authenticated users. \n" \
            "Press <b>Browse</b> to select a directory from the local filesystem.\n" \
            "</p>\n"
        ),
        #-----------================= PERFORMANCE SCREEN =============----------
        #

        # performance  Max Idle Time  help 1/1
        "MaxIdleTime"      => _(
          "<p><b>Max Idle Time:</b><br>\n" \
            "The maximum time (timeout) a remote client \n" \
            "may wait between FTP commands.\n" \
            "</p>\n"
        ),
        # performance max clients per IP  help 1/1
        "MaxClientsPerIP"  => _(
          "<p><b>Max Clients for One IP:</b><br>\n" \
            "The maximum number of clients allowed to connect\n" \
            "from the same source internet address. \n" \
            "</p>\n"
        ),
        # performance max clients help 1/1
        "MaxClientsNumber" => _(
          "<p><b>Max Clients:</b><br>\n" \
            "The maximum number of clients allowed to connect. \n" \
            "Any additional clients trying to connect will get an error message.\n" \
            "</p>\n"
        ),
        # performance local max rate help 1/1
        "LocalMaxRate"     => _(
          "<p><b>Local Max Rate:</b><br>\n" \
            "The maximum data transfer rate permitted for local authenticated users.\n" \
            "</p>"
        ),
        # performance  anonymous max rate help 1/1
        "AnonMaxRate"      => _(
          "<p><b>Anonymous Max Rate:</b><br>\nThe maximum data transfer rate permitted for anonymous clients.</p>\n"
        ),
        #-----------================= Authentication SCREEN =============----------
        #

        # authentication  Enable/Disable Anonymous and Local help 1/1
        "AnonAuthen"       => _(
          "<p><b>Enable/Disable Anonymous and Local Users</b><br>\n" \
            "<b>Anonymous Only</b>: If enabled, only anonymous logins are permitted.\n" \
            "<b>Authenticated Users Only</b>: If enabled, only authenticated users are permitted.\n" \
            "<b>Both</b> If enabled, authenticated users and anonymous users are permitted.\n" \
            "</p>\n"
        ),
        # authentication  Enable Upload help 1/1
        "EnableUpload"     => _(
          "<p><b>Enable Upload</b><br>\n" \
            "If enabled, FTP users can upload. To allow anonymous users \n" \
            "to upload, enable <b>Anonymous Can Upload</b>.\n" \
            "</p>\n"
        ),
        # authentication Anonymous Can Upload help 1/1
        "AnonReadOnly"     => _(
          "<p><b>Anonymous Can Upload</b><br>\n" \
            "If enabled anonymous users will be permitted to upload.\n" \
            "<i>vsftpd only: </i>If you want to allow anonymous users to upload, you \n" \
            "need an existing directory with write permission in the home directory after login.\n" \
            "</p>\n"
        ),
        # authentication Anonymous Can Create Dirs help 1/1
        "AnonCreatDirs"    => _(
          "<p><b>Anonymous Can Create Dirs</b><br>\n" \
            "If enabled, anonymous users can create directories.\n" \
            "<i>vsftpd only:</i> If you want to allow anonymous users to create directories,\n" \
            "you need an existing directory with write permission in the home directory after login.</p>\n"
        ),
        #-----------================= EXPERT SETTINGS SCREEN =============----------
        #

        # expert settings Enable Passive Mode help 1/1
        "PassiveMode"      => _(
          "<p><b>Enable Passive Mode</b><br>\n" \
            "If enabled, the FTP server will allow passive mode for connections.   \n" \
            "</p>\n"
        ),
        # expert settings Min Port for Pas. Mode help 1/1
        "PasMinPort"       => _(
          "<p><b>Min Port for Passive Mode</b><br>\n" \
            "Minimum value for a port range for passive connection replies.\n" \
            "This is used for protection by means of a firewall. \n" \
            "</p>\n"
        ),
        # expert settings Max Port for Pas. Mode help 1/1
        "PasMaxPort"       => _(
          "<p><b>Max Port for Pas. Mode</b><br>\n" \
            "Maximum value for a port range for passive connection replies.\n" \
            " This is used for protection by means of a firewall. \n" \
            "</p>\n"
        ),
        # expert settings  Enable SSL help 1/1
        "SSLEnable"        => _(
          "<p><b>Enable SSL</b><br>\n" \
            "If enabled, SSL connections are allowed.\n" \
            "</p>\n"
        ),
        # expert settings Enable TLS  help 1/1
        "TLS"              => _(
          "<p><b>Enable TLS</b><br>\n" \
            "If enabled, TLS connections are allowed.\n" \
            "</p>\n"
        ),
        # expert settings RSA Certificate to Use for SSL Encrypted Connections help 1/1
        "CertFile"         => _(
          "<p><b>RSA Certificate to Use for SSL-encrypted Connections</b><br>\n" \
            "This option specifies the location of the RSA certificate to \n" \
            "use for SSL-encrypted connections. Select a file by pressing <b>Browse</b>.\n" \
            "</p>\n"
        ),
        # expert settings Disable Downloading Unvalidated Data help 1/1
        "AntiWarez"        => _(
          "<p><b>Disable Downloading Unvalidated Data</b><br>\n" \
            "Disallow downloading of files that were uploaded \n" \
            "but not validated by a local admin.\n" \
            "</p>\n"
        ),
        # expert settings Security Settings help 1/1
        "SSL"              => _(
          "<p><b>Security Settings</b><br>\n" \
            "<i>Disable SSL/TLS</i> Disable SSL/TLS encryption layer.\n" \
            "<i>Accept SSL and TLS</i> Accept both, traditional and encrypted sessions.\n" \
            "<i>Refuse Connections Without SSL/TLS</i> Refuse connections that do not use SSL/TLS security mechanisms, including anonymous sessions.\n" \
            "</p>"
        ),
        #-----------================= SUMMARY =============----------
        #

        # Summary dialog help 1/3
        "summary"          => _(
          "<p><b><big>FTP Server Configuration</big></b><br>\nConfigure the FTP server.<br></p>\n"
        ) +
          # Summary dialog help 2/3
          _(
            "<p><b><big>Adding an FTP Server:</big></b><br>\n" \
              "Choose an FTP server from the list of detected FTP servers.\n" \
              "If your FTP server was not detected, use <b>Other (not detected)</b>.\n" \
              "Then press <b>Configure</b>.</p>\n"
          ) +
          # Summary dialog help 3/3
          _(
            "<p><b><big>Editing or Deleting</big></b><br>\n" \
              "If you press <b>Edit</b>, an additional dialog in which to change\n" \
              "the configuration opens.</p>\n"
          ),
        # Ovreview dialog help 1/3
        "overview"         => _(
          "<p><b><big>FTP Server Configuration Overview</big></b><br>\n" \
            "Obtain an overview of the installed FTP servers. Additionally,\n" \
            "edit their configurations.<br></p>\n"
        ) +
          # Ovreview dialog help 2/3
          _(
            "<p><b><big>Adding a FTP Server</big></b><br>\nPress <b>Add</b> to configure a FTP server.</p>\n"
          ) +
          # Ovreview dialog help 3/3
          _(
            "<p><b><big>Editing or Deleting</big></b><br>\n" \
              "Choose a FTP server to change or remove.\n" \
              "Then press <b>Edit</b> or <b>Delete</b> respectively.</p>\n"
          )
      }
    end

    def DialogHelpText(identification)
      Ops.get_string(
        @HELPS,
        identification,
        Builtins.sformat("Help for '%1' is missing!", identification)
      )
    end
  end
end
