#!/usr/bin/env ruby

#	Import Sorter
#	Copyright Gamua GmbH. All Rights Reserved.
#
#	This program is free software. You can redistribute and/or modify it
#	in accordance with the terms of the accompanying license agreement.

require 'optparse'

ROOT = File.expand_path('../..', __dir__)
DEFAULT_PATHS = %w[starling/src tests/src samples].map { |path| File.join(ROOT, path) }

# Consecutive import lines, possibly separated by blank lines.
IMPORT_REGION = /^[ \t]*import [^\n]+;[ \t]*\r?\n(?:(?:[ \t]*\r?\n)*[ \t]*import [^\n]+;[ \t]*\r?\n)*/

# Compares package segments, so that 'Matrix' comes before 'Matrix3D'.
def segments(import)
  import.delete_prefix('import ').delete_suffix(';').split('.')
end

# Sorts the imports and puts each top-level package (flash, starling, ...) into its own block.
def sort_region(region)
  indent = region[/\A[ \t]*/]
  newline = region.include?("\r\n") ? "\r\n" : "\n"
  imports = region.lines.map(&:strip).reject(&:empty?).uniq.sort_by { |import| segments(import) }
  blocks = imports.chunk { |import| segments(import).first }.map do |_, block|
    block.map { |import| indent + import + newline }.join
  end
  blocks.join(newline)
end

fix = false
OptionParser.new do |opts|
  opts.banner = "Usage: import_sorter.rb [--fix] [file or folder ...]\n" \
                "Checks that the imports in ActionScript files are sorted alphabetically.\n" \
                "Without arguments, it checks the library, the tests and the samples."
  opts.on('--fix', 'Sort the imports instead of only reporting them') { fix = true }
end.parse!

paths = ARGV.empty? ? DEFAULT_PATHS : ARGV
files = paths.flat_map { |path| File.directory?(path) ? Dir["#{path}/**/*.as"] : [path] }.sort

unsorted = files.select do |file|
  source = File.read(file)
  result = source.gsub(IMPORT_REGION) { |region| sort_region(region) }
  next false if result == source

  File.write(file, result) if fix
  true
end

unsorted.each { |file| puts "#{fix ? 'Sorted' : 'Unsorted'} imports: #{file}" }

if !fix && !unsorted.empty?
  puts "Run 'util/import_sorter/import_sorter.rb --fix' to sort them."
  exit 1
end
