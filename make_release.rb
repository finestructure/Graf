#!/usr/bin/ruby

# global constants
PRODUCT_NAME = "Graf"
MANIFEST_TEMPLATE = "Resources/graf_manifest.plist"
INDEX_HTML_TEMPLATE = "Resources/index.html"
DEV_CERTIFICATE = "iPhone Developer: Sven Schmidt (L686FULC28)"
PROV_PROFILES_DIR = "/Users/sas/Library/MobileDevice/Provisioning Profiles"

# more constants, probably no need to update
PROJECT_DIR = Dir.pwd
RELEASE_DIR = "#{PROJECT_DIR}/releases"
BUILD_PRODUCT = "build/Release-iphoneos/#{PRODUCT_NAME}.app"
PUBLISHING_TARGET = "abslogin:/home/sas/public_html/#{PRODUCT_NAME}/"


def find_provisioning_profile
  files = Dir.glob("#{PROV_PROFILES_DIR}/*.mobileprovision")
  if files.size == 1
    return files[0]
  else
    raise "Need a single provisioning profile in #{PROV_PROFILES_DIR}"
  end
end


def build
  cmd = "xcodebuild -target #{PRODUCT_NAME} -configuration Release"
  %x[#{cmd}]
  if $?.exitstatus == 0
    puts "Build succeeded"
  else
    raise "Build failed, command was:\n#{cmd}"
  end
end


def version
  res = %x[/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" #{BUILD_PRODUCT}/Info.plist]
  return res.strip
end


def ipafile
  base = File.basename(BUILD_PRODUCT, '.app')
  return "#{RELEASE_DIR}/#{base}_#{version}.ipa"
end


def codesign
  prov_profile = find_provisioning_profile
  cmd = "/usr/bin/xcrun -sdk iphoneos PackageApplication -v #{BUILD_PRODUCT} -o #{ipafile} --sign \"#{DEV_CERTIFICATE}\" --embed \"#{prov_profile}\""
  %x[#{cmd}]
  if $?.exitstatus == 0
    puts "Codesign succeeded"
  else
    raise "Codesign failed, command was:\n#{cmd}"
  end
end


def publish
  puts "Publish version #{version}? [y/N] "
  reply = STDIN.getc
  if not (reply == 10 or reply == 121 or reply == 89) # \n y Y
    puts "Aborted"
    exit
  end

  ipafiles = Dir.glob("#{RELEASE_DIR}/*.ipa")
  names = []
  manifests = []
  ipafiles.reverse.each {|ipafile|
    base = File.basename(ipafile, '.ipa')
    manifest = "manifest_#{base}.plist"
    names << "'#{base.sub('_', ' ')}'"
    manifests << "'#{manifest}'"
    if not File.exist?(manifest)
      %x[sed "s/IPAFILE/#{base}.ipa/" #{MANIFEST_TEMPLATE} > #{RELEASE_DIR}/#{manifest}]
    end 
  }
  manifests = "[#{manifests.join(',')}]"
  names = "[#{names.join(',')}]"
  cmd = %=sed "s/NAMES/#{names}/" #{INDEX_HTML_TEMPLATE} | sed "s/MANIFESTS/#{manifests}/" > #{RELEASE_DIR}/index.html=
  %x[#{cmd}]
  
  %x[rsync #{RELEASE_DIR}/* #{PUBLISHING_TARGET}]
end


if __FILE__ == $0
  
  build
  codesign
  publish

end
