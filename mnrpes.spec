%{!?ruby_sitelib: %global ruby_sitelib %(ruby -rrbconfig -e "puts RbConfig::CONFIG['sitelibdir']")}
%define release %{rpm_release}%{?dist}

Summary: MCollective based system to scale NRPE checks
Name: mnrpes
Version: %{version}
Release: %{release}
Group: System Tools
License: ASL 2.0
URL: http://devco.net/
Source0: %{name}-%{version}-%{rpm_release}.tgz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires: ruby(abi) >= 1.8
Requires: nagios
Requires: rubygem-rufus-scheduler
Requires: mcollective-common >= 2.2.0
BuildArch: noarch
Packager: R.I.Pienaar <rip@devco.net>

%description
A MCollective based framework that uses the NRPE agent to do async scheduling
of requests, replies as spoolver over the middleware into a queue and then fed
into Nagios via its command file.

This prevents a lot of forking on the Nagios machine sending that cost over to
the network, on the Nagios server there are just 2 long running processes.

%prep
%setup -q -n %{name}-%{version}-%{rpm_release}

%build

%install
rm -rf %{buildroot}
%{__install} -d -m0755  %{buildroot}/%{ruby_sitelib}/mnrpes
%{__install} -d -m0755  %{buildroot}/etc/mnrpes
%{__install} -d -m0755  %{buildroot}%{_sysconfdir}/init.d
%{__install} -d -m0755  %{buildroot}/usr/bin
%{__install} -m0755 bin/mnrpes-receiver.rb %{buildroot}/usr/bin/mnrpes-receiver
%{__install} -m0755 bin/mnrpes-scheduler.rb %{buildroot}/usr/bin/mnrpes-scheduler
%{__install} -d -m0755  %{buildroot}/var/log/mnrpes
%{__install} -d -m0755  %{buildroot}/var/run/mnrpes
%{__install} -m0755 mnrpes-receiver.init %{buildroot}%{_sysconfdir}/init.d/mnrpes-receiver
%{__install} -m0755 mnrpes-scheduler.init %{buildroot}%{_sysconfdir}/init.d/mnrpes-scheduler
cp -R lib/mnrpes.rb %{buildroot}/%{ruby_sitelib}/
cp -R lib/mnrpes/* %{buildroot}/%{ruby_sitelib}/mnrpes/
cp etc/*.dist %{buildroot}/etc/mnrpes/

%clean
rm -rf %{buildroot}

%post
/sbin/chkconfig --add mnrpes-receiver || :
/sbin/chkconfig --add mnrpes-scheduler || :

%postun
if [ "$1" -ge 1 ]; then
  /sbin/service mnrpes-receiver condrestart &>/dev/null || :
  /sbin/service mnrpes-scheduler condrestart &>/dev/null || :
fi

%preun
if [ "$1" = 0 ] ; then
  /sbin/service mnrpes-scheduler stop > /dev/null 2>&1
  /sbin/service mnrpes-receiver stop > /dev/null 2>&1
  /sbin/chkconfig --del mnrpes-scheduler || :
  /sbin/chkconfig --del mnrpes-receiver || :
fi

%files
%{ruby_sitelib}/mnrpes.rb
%{ruby_sitelib}/mnrpes
%config(noreplace) /etc/mnrpes
/usr/bin/mnrpes-receiver
/usr/bin/mnrpes-scheduler
%{_sysconfdir}/init.d/mnrpes-receiver
%{_sysconfdir}/init.d/mnrpes-scheduler
%defattr(0755,nagios,nagios,0755)
/var/log/mnrpes
/var/run/mnrpes

%changelog
* Mon Dec 31 2012 R.I.Pienaar <rip@devco.net> - 0.1
- First release
