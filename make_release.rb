#!/usr/bin/ruby

require 'fileutils'

# global constants
PRODUCT_NAME = "Graf"
MANIFEST_TEMPLATE = "Resources/graf_manifest.plist"
INDEX_HTML_TEMPLATE = "Resources/index.html"
DEV_CERTIFICATE = "iPhone Developer: Sven Schmidt (L686FULC28)"
PROV_PROFILES_DIR = "/Users/sas/Library/MobileDevice/Provisioning Profiles"
PROV_PROFILE = "CB2C9073-B182-4783-B4EF-A6B609B26018.mobileprovision"

# more constants, probably no need to update
PROJECT_DIR = Dir.pwd
RELEASE_DIR = "#{PROJECT_DIR}/releases"
BUILD_PRODUCT = "build/Release-iphoneos/#{PRODUCT_NAME}.app"
PUBLISHING_TARGET = "abslogin:/home/sas/public_html/#{PRODUCT_NAME}/"


def find_provisioning_profile
  fname = "#{PROV_PROFILES_DIR}/#{PROV_PROFILE}"
  if not File.exist?(fname)
    raise "Provisioning profile not found: #{PROV_PROFILE}"
  end
end


def build
  puts "Building ..."
  cmd = "xcodebuild -target #{PRODUCT_NAME} -configuration Release clean build"
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
  if not File.exist?(RELEASE_DIR)
    Dir.mkdir(RELEASE_DIR)
  end
  return "#{RELEASE_DIR}/#{base}_#{version}.ipa"
end


def codesign
  puts "Codesigning ..."
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
  puts "Publishing ..."
  ipafiles = Dir.glob("#{RELEASE_DIR}/*.ipa")
  names = []
  manifests = []
  ipafiles.reverse.each {|ipafile|
    puts "Adding #{ipafile}"
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

  ['Resources/app_icon-57.png', 'Resources/app_icon-114.png'].each {|fname|
    base = File.basename(fname)
    target = "#{RELEASE_DIR}/#{base}"
    if not File.exist?(target)
      FileUtils.cp(fname, target)
    end
  }

  puts "Publish? [Y/n] "
  reply = STDIN.getc
  if not (reply == 10 or reply == 121 or reply == 89) # \n y Y
    puts "Aborted"
    exit
  end

  %x[rsync #{RELEASE_DIR}/* #{PUBLISHING_TARGET}]
end


if __FILE__ == $0

  if ARGV.size == 1
    command = ARGV[0]
  else
    command = 'all'
  end
 
  if command == 'all'
    build
    codesign
    publish
  else
    case command
    when 'build'
      build
    when 'codesign'
      codesign
    when 'publish'
      publish
    else
      puts "Unknown command: #{command}"
    end
  end

  puts "Done."
end
