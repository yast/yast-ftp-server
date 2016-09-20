#
# spec file for package yast2-ftp-server
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-ftp-server
Version:        3.1.9
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:          System/YaST
License:        GPL-2.0
# Wizard::SetDesktopTitleAndIcon
Requires:       yast2 >= 2.21.22
Requires:	yast2-inetd
BuildRequires:	update-desktop-files yast2 yast2-testsuite
BuildRequires:  yast2-devtools >= 3.1.10
BuildRequires:  rubygem(%rb_default_ruby_abi:yast-rake)
BuildRequires:  rubygem(%rb_default_ruby_abi:rspec)

BuildArchitectures:	noarch

Requires:       yast2-ruby-bindings >= 1.0.0

Summary:	YaST2 - FTP configuration

%description
This package contains the YaST2 component for FTP configuration. It can
configure two daemons: pure-ftpd and vsftpd.

%prep
%setup -n %{name}-%{version}

%check
rake test:unit

%build

%install
rake install DESTDIR="%{buildroot}"

%files
%defattr(-,root,root)
%dir %{yast_yncludedir}/ftp-server
%{yast_yncludedir}/ftp-server/*
%{yast_clientdir}/ftp-server.rb
%{yast_clientdir}/ftp-server_*.rb
%{yast_moduledir}/FtpServer.*
%{yast_desktopdir}/ftp-server.desktop
%{yast_schemadir}/autoyast/rnc/ftp-server.rnc
%{yast_scrconfdir}/*.scr
%doc %{yast_docdir}
