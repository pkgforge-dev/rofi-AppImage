#!/bin/sh

set -ex

ARCH="$(uname -m)"
SHARUN="https://github.com/VHSgunzo/sharun/releases/latest/download/sharun-$ARCH-aio"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
URUNTIME_LITE="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-lite-$ARCH"
UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
PATCH="$PWD"/hack.patch

# CREATE DIRECTORIES
mkdir ./AppDir && (
	cd ./AppDir
	# DOWNLOAD AND BUILD ROFI
	git clone --depth 1 "https://github.com/davatorium/rofi.git" ./rofi && (
		cd ./rofi
		patch -p1 -i "$PATCH"
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

# turn appdir into appimage
wget --retry-connrefused --tries=30 "$URUNTIME"      -O  ./uruntime
wget --retry-connrefused --tries=30 "$URUNTIME_LITE" -O  ./uruntime-lite
chmod +x ./uruntime*

# Keep the mount point (speeds up launch time)
sed -i 's|URUNTIME_MOUNT=[0-9]|URUNTIME_MOUNT=0|' ./uruntime-lite

# Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime-lite --appimage-addupdinfo "$UPINFO"

echo "Generating AppImage..."
./uruntime \
	--appimage-mkdwarfs -f               \
	--set-owner 0 --set-group 0          \
	--no-history --no-create-timestamp   \
	--compression zstd:level=22 -S26 -B8 \
	--header uruntime-lite               \
	-i ./AppDir                          \
	-o ./rofi-"$VERSION"-anylinux-"$ARCH".AppImage

# make appbundle
UPINFO="$(echo "$UPINFO" | sed 's#.AppImage.zsync#*.AppBundle.zsync#g')"
wget --retry-connrefused --tries=30 \
	"https://github.com/xplshn/pelf/releases/latest/download/pelf_$ARCH" -O ./pelf
chmod +x ./pelf
echo "Generating [dwfs]AppBundle..."
./pelf \
	--compression "-C zstd:level=22 -S26 -B8"      \
	--appbundle-id="rofi-$VERSION"                 \
	--appimage-compat --disable-use-random-workdir \
	--add-updinfo "$UPINFO"                        \
	--add-appdir ./AppDir                          \
	--output-to ./rofi-"$VERSION"-anylinux-"$ARCH".dwfs.AppBundle

echo "Generating zsync file..."
zsyncmake ./*.AppImage -u ./*.AppImage
zsyncmake ./*.AppBundle -u ./*.AppBundle

mkdir -p ./dist
mv -v ./*.AppImage* ./dist
mv -v ./*.AppBundle* ./dist

echo "All Done!"
