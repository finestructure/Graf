#!/bin/sh

# variables
product_name="Graf"
manifest="graf_manifest.plist"
dev_certificate="iPhone Developer: Sven Schmidt (L686FULC28)"
prov_profiles="/Users/sas/Library/MobileDevice/Provisioning Profiles"

# more variables, probably no need to change
project_dir=`pwd`
product="build/Release-iphoneos/$product_name.app"
publishing_target="abslogin:~/public_html/$product_name/"
tempdir=.tmp

# find prov profile
count=$(ls -1 "$prov_profiles"/*.mobileprovision | wc -l)
if [ $count == 1 ]
then
  prov_profile=$(ls -1 "$prov_profiles"/*.mobileprovision)
else
  echo Need a single provisioning profile in $prov_profiles, but found:
  ls -1 $prov_profiles
  exit 1
fi

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

/usr/bin/xcrun -sdk iphoneos PackageApplication -v $product -o `pwd`/releases/$ipafile --sign "$dev_certificate" --embed "$prov_profile"

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

