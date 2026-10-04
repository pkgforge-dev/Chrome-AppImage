#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	binutils            \
	flac                \
	glu                 \
	gvfs                \
	libepoxy            \
	libheif             \
	libsm               \
	librsvg             \
	libtiff             \
	nss                 \
	pipewire-audio      \
	pipewire-jack       \
	pulseaudio-alsa     \
	vulkan-mesa-layers  \
	wget                \
	xcb-util-cursor     \
	xcb-util-keysyms    \
	xcb-util-wm         \
	zsync

if [ "$ARCH" = 'x86_64' ]; then
	pacman -Syu --noconfirm libva-intel-driver
fi

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano intel-media-driver-mini ffmpeg-mini

# Comment this out if you need an AUR package
#make-aur-package PACKAGENAME

echo "Getting binary..."
echo "---------------------------------------------------------------"
case "$ARCH" in
	aarch64) deb_arch=arm64;;
	x86_64)  deb_arch=amd64;;
esac

CHROME_CHANNEL=${CHROME_CHANNEL:-stable}
case "$CHROME_CHANNEL" in
	beta)
		pkg=google-chrome-beta
		chrome_dir=chrome-beta
		desktop=google-chrome-beta.desktop
		icon=google-chrome-beta
		logo=product_logo_256_beta.png
		;;
	canary)
		pkg=google-chrome-canary
		chrome_dir=chrome-canary
		desktop=google-chrome-canary.desktop
		icon=google-chrome-canary
		logo=product_logo_256_canary.png
		;;
	*)
		pkg=google-chrome-stable
		chrome_dir=chrome
		desktop=google-chrome.desktop
		icon=google-chrome
		logo=product_logo_256.png
		;;
esac

CHROME_URL="https://dl.google.com/linux/direct/${pkg}_current_${deb_arch}.deb"

wget --retry-connrefused --tries=30 "$CHROME_URL" -O /tmp/temp.deb
ar xvf /tmp/temp.deb
tar xvf ./data.tar.xz
tar -xf ./control.tar.* ./control -O | awk -F': |-' '/^Version:/{print $2; exit}' > ~/version

# Pin the exact version that was downloaded, the pool URL allows fetching
# that exact .deb again at runtime (and downgrades if the AppImage does)
CHROME_URL="https://dl.google.com/linux/chrome/deb/pool/main/g/${pkg}/${pkg}_$(cat ~/version)-1_${deb_arch}.deb"

mkdir -p ./AppDir/bin
mv -v ./opt/google/$chrome_dir/* ./AppDir/bin
cp -v ./usr/share/applications/$desktop ./AppDir
cp -v ./AppDir/bin/$logo ./AppDir/$icon.png

rm -f ./AppDir/bin/google-chrome

# Symlink so the desktop entry's Exec command resolves to chrome
ln -sf chrome ./AppDir/bin/google-chrome-"$CHROME_CHANNEL"

# we need to remove this because chrome otherwise dlopen libQt5Core on the host
# when present, we can only bunle libqt6 or libqt5 but not both
rm -f ./AppDir/bin/libqt5_shim.so

# Chrome cannot be redistributed, save the download link and download at runtime
echo "$CHROME_URL" > ./AppDir/.chrome-link
echo "$CHROME_CHANNEL" > ./AppDir/.chrome-channel
find ./AppDir/bin -mindepth 1 -maxdepth 1 ! -name '*.hook' -printf '%f\n' > ./AppDir/.chrome-files

# if you also have to make nightly releases check for DEVEL_RELEASE = 1
#
# if [ "${DEVEL_RELEASE-}" = 1 ]; then
# 	nightly build steps
# else
# 	regular build steps
# fi
