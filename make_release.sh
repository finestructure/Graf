#!/bin/sh

# variables
product_name="Graf"
manifest="graf_manifest.plist"
dev_certificate="iPhone Developer: Sven Schmidt (L686FULC28)"
prov_profile="/Users/sas/Library/MobileDevice/Provisioning Profiles/8A90C6D1-7099-4E4A-8F8E-BCE9F790F102.mobileprovision"

# more variable, probably no need to change
project_dir=`pwd`
product="build/Release-iphoneos/$product_name.app"
publishing_target="abslogin:~/public_html/$product_name/"
tempdir=.tmp

# build release
xcodebuild -target $product_name -configuration Release

# check if build succeeded
if [ $? != 0 ]
then
  echo "Build failed"
  exit 1
fi

# get version
version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" $product/Info.plist)

base=$(basename "$product" .app)
ipafile="$base"_$version.ipa

/usr/bin/xcrun -sdk iphoneos PackageApplication -v $product -o `pwd`/releases/$ipafile --sign $dev_certificate --embed $prov_profile

echo Version: $version

# update publishing files
rm -rf $tempdir
mkdir $tempdir
sed "s/VERSION/$version/" releases/index.html > $tempdir/index.html
sed "s/IPAFILE/$ipafile/" releases/$manifest > $tempdir/$manifest

# upload files
echo Copying to host...
scp releases/$ipafile $publishing_target
scp $tempdir/index.html $publishing_target
scp $tempdir/$manifest $publishing_target
scp Resources/app_icon-57.png $publishing_target
scp Resources/app_icon-114.png $publishing_target

# clean up
rm -rf $tempdir

