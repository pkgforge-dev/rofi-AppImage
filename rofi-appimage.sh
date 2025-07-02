#!/bin/sh

set -ex

ARCH="$(uname -m)"
UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
SHARUN="https://github.com/VHSgunzo/sharun/releases/latest/download/sharun-$ARCH-aio"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
URUNTIME_LITE="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-lite-$ARCH"

# CREATE DIRECTORIES
mkdir ./AppDir && (
	cd ./AppDir
	# DOWNLOAD AND BUILD ROFI
	git clone --depth 1 "https://github.com/davatorium/rofi.git" ./rofi && (
		cd ./rofi
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
		./bin/*                \
		/usr/lib/gio/modules/* \
		/usr/lib/gdk-pixbuf-*/*/*/*
	rm -f ./sharun-aio

	# We can't use the gdk variables here because that breaks child processes
	#git clone --depth 1 "https://github.com/fritzw/ld-preload-open" && (
	#	cd ./ld-preload-open
	#	make all
	#	mv ./path-mapping.so ../lib
	#)
	#mv -v ./shared/lib/gdk-pixbuf-* ./
	#echo 'path-mapping.so' >./.preload
	#echo 'PATH_MAPPING=/usr/lib/gdk-pixbuf-2.0:${SHARUN_DIR}/gdk-pixbuf-2.0' >> ./.env
	rm -rf ./rofi ./usr ./ld-preload-open
	
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

VERSION="$(./AppDir/AppRun -v | awk '{print $2; exit}')"
echo "$VERSION" > ~/version

# turn appdir into appimage
wget --retry-connrefused --tries=30 "$URUNTIME"      -O  ./uruntime
wget --retry-connrefused --tries=30 "$URUNTIME_LITE" -O  ./uruntime-lite
chmod +x ./uruntime*

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

mkdir -p ./dist
mv -v ./*.AppImage* ./dist

echo "All Done!"
