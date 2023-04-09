FROM alpine
COPY breakin.* mkinitfs.conf mce.sh init build.sh /
RUN apk update && apk upgrade && apk add --no-cache linux-lts linux-headers \
    alpine-sdk dropbear-ssh util-linux-misc mkinitfs curl-dev ncurses-dev \
    openmpi-dev openblas-dev rasdaemon syslinux grub grub-bios grub-efi \
    xorriso
CMD ["/bin/sh", "/build.sh"]

