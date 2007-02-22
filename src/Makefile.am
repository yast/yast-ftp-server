# Makefile.am for ftpd/src

yncludedir = @yncludedir@/ftpd

client_DATA =			\
	ftpd.ycp		\
	ftpd_auto.ycp	

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	complex.ycp		\
	wid_functions.ycp	\
	uiforms.ycp		\
	write_load.ycp

desktop_DATA =			\
	ftpd.desktop

module_DATA =			\
	Ftpd.ycp
	
# create a symlink for local build, #145327
ftpd:
	ln -sf . $@
ycpchook = ftpd

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
