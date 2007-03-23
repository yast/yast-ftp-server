# Makefile.am for ftp-server/src

yncludedir = @yncludedir@/ftp-server

client_DATA =			\
	ftp-server.ycp		\
	ftp-server_auto.ycp	

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	complex.ycp		\
	wid_functions.ycp	\
	uiforms.ycp		\
	write_load.ycp

desktop_DATA =			\
	ftp-server.desktop

module_DATA =			\
	FtpServer.ycp
	
# create a symlink for local build, #145327
ftp-server:
	ln -sf . $@
ycpchook = ftp-server

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
