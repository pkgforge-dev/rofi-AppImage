#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	check                \
	cppcheck             \
	gvfs                 \
	meson                \
	pango                \
	startup-notification \
	wget                 \
	xcb-util-cursor      \
	xcb-util             \
	xcb-util-keysyms     \
	xcb-util-wm          \
	xcb-util-xrm         \
	xkeyboard-config     \
	wayland-protocols

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

echo "Building rofi..."
echo "---------------------------------------------------------------"
git clone --depth 1 "https://github.com/davatorium/rofi.git" ./rofi && (
	cd ./rofi
	meson -Dwayland=enabled -Dxcb=enabled --prefix /usr . build
	meson compile -C build
	meson install -C build
)
/usr/bin/rofi -v | awk -F'[- ]' '{print $2; exit}' > ~/version
