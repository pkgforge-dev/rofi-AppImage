#!/bin/sh

set -ex
ARCH="$(uname -m)"

echo "Installing build dependencies..."
echo "---------------------------------------------------------------"

case "$ARCH" in
	'x86_64')  PKG_TYPE='x86_64.pkg.tar.zst';;
	'aarch64') PKG_TYPE='aarch64.pkg.tar.xz';;
	''|*) echo "Unknown arch: $ARCH"; exit 1;;
esac

LIBXML_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/libxml2-iculess-$PKG_TYPE"

pacman -Syu --noconfirm \
	base-devel           \
	bison                \
	cairo                \
	check                \
	cppcheck             \
	flex                 \
	gdk-pixbuf2          \
	git                  \
	gvfs                 \
	librsvg              \
	libxcb               \
	libxkbcommon         \
	libxkbcommon-x11     \
	meson                \
	pango                \
	patch                \
	startup-notification \
	wget                 \
	xcb-util-cursor      \
	xcb-util             \
	xcb-util-keysyms     \
	xcb-util-wm          \
	xcb-util-xrm         \
	xkeyboard-config


echo "Installing debloated pckages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$LIBXML_URL" -O ./libxml2-iculess.pkg.tar.zst

pacman -U --noconfirm ./*.pkg.tar.zst
rm -f ./*.pkg.tar.zst

echo "All done!"
echo "---------------------------------------------------------------"
