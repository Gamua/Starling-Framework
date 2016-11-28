#!/usr/bin/ruby

require "rexml/document"
require "fileutils"
include REXML

ALL_PLATFORMS = "all-platforms"
platforms = ["ios", "android", "air-desktop"]
script_name = File.basename(__FILE__)

if ARGV.count < 1
  puts "Usage: #{script_name} module.iml [platform]"
  puts "  - platform being one of: #{platforms.join(', ')}"
  puts "  - omit 'platform' to copy all resources"
  exit
end

module_file = ARGV[0]
platform = ARGV.count > 1 ? ARGV[1].downcase : ALL_PLATFORMS

unless (platform == ALL_PLATFORMS or platforms.include? platform)
  puts "Invalid platform: #{platform}"
  exit
end

unless File.exist?(module_file)
  puts "Module file not found: #{module_file}"
  exit
end

puts "Copying resources for #{File.basename(module_file)} (#{platform}) ..."

module_dir = File.dirname(module_file)
module_doc = Document.new(File.open(module_file))
configuration = XPath.first(module_doc, "//configuration")
output_folder = configuration.attributes["output-folder"].gsub("$MODULE_DIR$", module_dir)
copy_count = 0

packaging_platform =
  if platform == ALL_PLATFORMS then "//*[starts-with(name(), 'packaging-')]"
  else "//packaging-#{platform}"
  end

XPath.each(module_doc, "#{packaging_platform}/files-to-package/FilePathAndPathInPackage") do |entry|
  file_path = entry.attributes["file-path"].gsub("$MODULE_DIR$", module_dir)
  path_in_package = entry.attributes["path-in-package"]
  puts "  #{File.expand_path(file_path)} -> #{path_in_package}"
  FileUtils.mkdir_p path_in_package
  FileUtils.cp_r File.join(file_path, "."), File.join(output_folder, path_in_package)
  copy_count += 1
end

puts "Copied #{copy_count} resource-folder(s)."
