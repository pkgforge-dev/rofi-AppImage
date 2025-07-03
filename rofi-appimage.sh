#!/bin/sh

set -ex

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
export URUNTIME_PRELOAD=1

UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
SHARUN="https://github.com/VHSgunzo/sharun/releases/latest/download/sharun-$ARCH-aio"
APPIMAGETOOL="https://github.com/pkgforge-dev/appimagetool-uruntime/releases/download/continuous/appimagetool-$ARCH.AppImage"
PATCH="$PWD"/hack.patch

# CREATE DIRECTORIES
mkdir ./AppDir && (
	cd ./AppDir
	# DOWNLOAD AND BUILD ROFI
	git clone --depth 1 "https://github.com/davatorium/rofi.git" ./rofi && (
		cd ./rofi
		cp -v "$PATCH" ./hack.patch
		patch -p1 -i ./hack.patch
		meson --prefix /usr . build
		meson compile -C build
		meson install -C build --destdir "$(realpath ../)"
	)
	mv -v ./usr/* ./
	cp -v ./share/icons/hicolor/scalable/apps/rofi.svg  ./
	cp -v ./share/icons/hicolor/scalable/apps/rofi.svg  ./.DirIcon
	cp -v ./share/applications/rofi.desktop             ./
	echo "Categories=Utility;" >> ./rofi.desktop
	
	# ADD LIBRARIES
	wget --retry-connrefused --tries=30 "$SHARUN" -O ./sharun-aio
	chmod +x ./sharun-aio
	./sharun-aio l -p -v -k -s \
		./bin/*                     \
		/usr/lib/gdk-pixbuf-*/*/*/* \
		/usr/lib/gio/modules/libgvfsdbus.so
	rm -rf ./sharun-aio ./rofi ./usr
	
	# AppRun
	cat > ./AppRun <<-'EOF'
	#!/bin/sh
	CURRENTDIR="$(dirname "$(readlink -f "$0")")"
	
	BIN="${ARGV0#./}"
	unset ARGV0
	DATADIR="${XDG_DATA_HOME:-$HOME/.local/share}"
	
	export XDG_DATA_DIRS="$DATADIR:$XDG_DATA_DIRS:/usr/local/share:/usr/share"
	export PATH="$CURRENTDIR/bin:$PATH"
	
	if [ ! -d "$DATADIR"/rofi/themes ]; then
	        mkdir -p "$DATADIR"/rofi || exit 1
	        cp -rn "$CURRENTDIR"/share/rofi/themes "$DATADIR"/rofi/themes || exit 1
	fi
	
	if [ "$1" = "rofi-theme-selector" ]; then
	        shift
	        exec "$CURRENTDIR/bin/rofi-theme-selector" "$@"
	elif [ -f "$CURRENTDIR/bin/$BIN" ]; then
	        exec "$CURRENTDIR/bin/$BIN" "$@"
	else
	        exec "$CURRENTDIR/bin/rofi" "$@"
	fi
	EOF
	
	chmod a+x ./AppRun
	./sharun -g
)

export VERSION="$(./AppDir/AppRun -v | awk -F'[- ]' '{print $2; exit}')"
echo "$VERSION" > ~/version

# MAKE APPIMAGE WITH FUSE3 COMPATIBLE APPIMAGETOOL
wget --retry-connrefused --tries=30 "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool

echo "Generating AppImage..."
./appimagetool -n -u "$UPINFO" \
	"$PWD"/AppDir "$PWD"/rofi-"$VERSION"-anylinux-"$ARCH".AppImage

mkdir -p ./dist
mv -v ./*.AppImage* ./dist

echo "All Done!"
