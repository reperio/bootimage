
# bootimage

A set of scripts, etc. for making a bootable image that runs
[breakin](https://github.com/reperio/breakin).

## Building with Github Actions

<div align="center">
<a href="https://github.com/reperio/bootimage/actions">
	<img src="https://github.com/reperio/bootimage/workflows/Build/badge.svg"/>
</a>
</div>

The ``Build`` job will run on every push. To make a new release, push a
new tag.

## Building on Docker

To generate the kernel and initramfs via Docker, start by building the
build container:
```sh
docker build . -t bootimage:latest
```

Then, to build ``breakin`` and generate the kernel + initramfs + ISO, run:
```sh
docker run -v "${PWD}":/mnt/out -it bootimage:latest
```

Upon success, you'll have three files ``vmlinux``, ``initramfs``,
and ``bootimg.iso`` in the current directory.

