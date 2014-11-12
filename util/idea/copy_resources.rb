#!/usr/bin/ruby

require "rexml/document"
require "fileutils"
include REXML

platforms = ["ios", "android", "air-desktop"]
script_name = File.basename(__FILE__)

if ARGV.count < 2
  puts "Usage: #{script_name} module.iml platform"
  puts "  (platform being one of: #{platforms.join(', ')})"
  exit
end

module_file = ARGV[0]
platform = ARGV[1].downcase

unless (platforms.include? platform)
  puts "Invalid platform: #{platform}"
  exit
end

unless File.exist?(module_file)
  puts "Module file not found: #{module_file}"
  exit
end

puts "Copying resources for #{File.basename(module_file)} (#{platform})"

module_dir = File.dirname(module_file)
module_doc = Document.new(File.open(module_file))
configuration = XPath.first(module_doc, "//configuration")
output_folder = configuration.attributes["output-folder"].gsub("$MODULE_DIR$", module_dir)

XPath.each(module_doc, "//packaging-#{platform}/files-to-package/FilePathAndPathInPackage") do |entry|
  file_path = entry.attributes["file-path"].gsub("$MODULE_DIR$", module_dir)
  path_in_package = entry.attributes["path-in-package"]
  puts "  #{File.expand_path(file_path)} -> #{path_in_package}"
  FileUtils.mkdir_p path_in_package
  FileUtils.cp_r File.join(file_path, "."), File.join(output_folder, path_in_package)
end

puts "Done!"