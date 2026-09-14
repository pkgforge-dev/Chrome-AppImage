#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.bg.hook:fix-namespaces.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export URUNTIME_PRELOAD=1 # really needed here
export STRACE_BINARY=chrome
export STRACE_FLAGS='google.com --no-sandbox'

# Deploy dependencies
quick-sharun \
	./AppDir/bin/* \
	/usr/bin/ar \
	/usr/bin/tar \
	/usr/bin/xz \
	/usr/lib/libcloudproviders* \
	/usr/lib/libgtk-3.so*

# Remove the proprietary blobs since they cannot be redistributed,
# they are downloaded and extracted to $DATADIR at runtime instead
while IFS= read -r blob; do
	find ./AppDir/bin ./AppDir/shared/bin \
	  -name "$blob" -exec rm -rf {} + 2>/dev/null || :
done < ./AppDir/.chrome-files
rm -rf ./AppDir/lib/__w

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the test fails due to the app
# having issues running in the CI use --simple-test instead
quick-sharun --test ./dist/*.AppImage --no-sandbox

# CI fails otherwise if this isn't done
chmod 755 ./
