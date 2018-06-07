%define name bootimage

Summary: Advanced Clustering Technologies Network Boot Image
Name: %{name}
Version: %{version}
Release: %{release}
Source: %{name}-%{version}.tbz2
License: no
Group: System Environment/Utilities
BuildArch: x86_64
BuildRoot: %{_tmppath}/%{name}-%{version}-buildroot
Provides: bootimage
URL: http://www.advancedclustering.com/software/breakin.html
BuildArch: noarch
Vendor: Advanced Clustering Technologies, Inc.
Packager: Kyle Sheumaker <ksheumaker@advancedclustering.com>

%description
Advanced Clustering Technologies' network boot image. This include Breakin 
(diagnostics and stress testing), Cloner (system provisioning), and a rescue
system.

%prep

%build

%install
mkdir -p $RPM_BUILD_ROOT/tftpboot/bootimage
mkdir -p $RPM_BUILD_ROOT/tftpboot/act_netboot_templates
mkdir -p $RPM_BUILD_ROOT/tftpboot/act_netboot_ipxe_templates
cp ${TOPDIR}/dist/act_netboot_templates/*.cfg $RPM_BUILD_ROOT/tftpboot/act_netboot_templates/
cp ${TOPDIR}/dist/act_netboot_ipxe_templates/*.ipxe $RPM_BUILD_ROOT/tftpboot/act_netboot_ipxe_templates/
cp ${TOPDIR}/dist/kernel-%{version} $RPM_BUILD_ROOT/tftpboot/bootimage/
cp ${TOPDIR}/dist/initrd-%{version}.cpio.lzma $RPM_BUILD_ROOT/tftpboot/bootimage/
# Create handy symlinks for initrd and kernel
ln -fs kernel-%{version} $RPM_BUILD_ROOT/tftpboot/bootimage/kernel
ln -fs initrd-%{version}.cpio.lzma $RPM_BUILD_ROOT/tftpboot/bootimage/initrd

%clean
rm -rf $RPM_BUILD_ROOT

%files
%config(noreplace) /tftpboot/act_netboot_templates/breakin.cfg
%config(noreplace) /tftpboot/act_netboot_templates/rescue.cfg
%config(noreplace) /tftpboot/act_netboot_templates/cloner.cfg
%config(noreplace) /tftpboot/act_netboot_templates/cloner-multicast.cfg
%config(noreplace) /tftpboot/act_netboot_templates/cloner3.cfg
%config(noreplace) /tftpboot/act_netboot_templates/cloner3-multicast.cfg
%config(noreplace) /tftpboot/act_netboot_ipxe_templates/breakin.ipxe
%config(noreplace) /tftpboot/act_netboot_ipxe_templates/rescue.ipxe
%config(noreplace) /tftpboot/act_netboot_ipxe_templates/cloner3.ipxe
%config(noreplace) /tftpboot/act_netboot_ipxe_templates/cloner3-multicast.ipxe

/tftpboot/bootimage/kernel-%{version}
/tftpboot/bootimage/initrd-%{version}.cpio.lzma
/tftpboot/bootimage/kernel
/tftpboot/bootimage/initrd

