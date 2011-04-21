%define name bootimage
%define version 3.20

Summary: Advanced Clustering Technologies Network Boot Image
Name: %{name}
Version: %{version}
Release: 1
Source: %{name}-%{version}.tbz2
License: no
Group: System Environment/Utilities
BuildArch: x86_64
BuildRoot: %{_tmppath}/%{name}-%{version}-buildroot
Provides: bootimage
URL: http://www.advancedclustering.com/software/breakin.html
BuildArch: noarch
Vendor: Advanced Clustering Technologies, Inc.
Packager: Jason Clinton <jclinton@advancedclustering.com>

%description
Advanced Clustering Technologies' network boot image. This include Breakin 
(diagnostics and stress testing), Cloner (system provisioning), and a rescue
system.

%prep

%build

%install
mkdir -p $RPM_BUILD_ROOT/tftpboot/bootimage
mkdir -p $RPM_BUILD_ROOT/tftpboot/act_netboot_templates
cp ${TOPDIR}/dist/act_netboot_templates/*.cfg $RPM_BUILD_ROOT/tftpboot/act_netboot_templates/
cp ${TOPDIR}/dist/kernel-%{version} $RPM_BUILD_ROOT/tftpboot/bootimage/
cp ${TOPDIR}/dist/initrd-%{version}.cpio.lzma $RPM_BUILD_ROOT/tftpboot/bootimage/
# Create handy symlinks for initrd and kernel
ln -s kernel-%{version} $RPM_BUILD_ROOT/tftpboot/bootimage/kernel
ln -s initrd-%{version}.cpio.lzma $RPM_BUILD_ROOT/tftpboot/bootimage/initrd

%clean
rm -rf $RPM_BUILD_ROOT

%files
%config(noreplace) /tftpboot/act_netboot_templates/breakin.cfg
%config(noreplace) /tftpboot/act_netboot_templates/rescue.cfg
%config(noreplace) /tftpboot/act_netboot_templates/cloner.cfg
%config(noreplace) /tftpboot/act_netboot_templates/cloner-multicast.cfg
/tftpboot/bootimage/kernel-%{version}
/tftpboot/bootimage/initrd-%{version}.cpio.lzma
/tftpboot/bootimage/kernel
/tftpboot/bootimage/initrd

