# Sources for ftp-server

module_DATA = \
  modules/FtpServer.rb

client_DATA = \
  clients/ftp-server_auto.rb \
  clients/ftp-server.rb

yncludedir = @yncludedir@/ftp-server
ynclude_DATA = \
  include/ftp-server/wid_functions.rb \
  include/ftp-server/wizards.rb \
  include/ftp-server/dialogs.rb \
  include/ftp-server/write_load.rb \
  include/ftp-server/complex.rb \
  include/ftp-server/helps.rb

scrconf_DATA = \
  scrconf/pure-ftpd.scr \
  scrconf/vsftpd.scr

schemafilesdir = $(schemadir)/autoyast/rnc
schemafiles_DATA = \
  autoyast-rnc/ftp-server.rnc

desktop_DATA = \
  desktop/ftp-server.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) $(schemafiles_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common