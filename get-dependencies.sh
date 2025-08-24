#!/bin/sh

set -ex
EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

echo "Installing build dependencies..."
echo "---------------------------------------------------------------"
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
	xkeyboard-config     \
	zsync

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
chmod +x ./get-debloated-pkgs.sh
./get-debloated-pkgs.sh libxml2-mini gtk3-mini
