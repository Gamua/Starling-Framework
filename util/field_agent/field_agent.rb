#!/usr/bin/ruby

#	Field Agent
#	Copyright Gamua GmbH. All Rights Reserved.
#
#	This program is free software. You can redistribute and/or modify it
#	in accordance with the terms of the accompanying license agreement.

require 'fileutils'
require 'optparse'
require 'ostruct'

script_name = File.basename(__FILE__)
input_file  = nil
output_file = nil

def windows_prompt?
  `echo \\(`.strip != "("
end

def log(message)
  puts "# Field agent: #{message}, Sir."
end

def fail(message)
  log message
  exit 1
end

# crude workaround so that the call to 'convert' works on Windows, too.
def system_xp(command)
  if windows_prompt?
    command.gsub!("'", '"')
    command.gsub!("%", "%%")
    command.gsub!("\\(", "(")
    command.gsub!("\\)", ")")
  end
  system command
end

# prepare the options and their parser
options = OpenStruct.new
options.spread = 8
options.quality = 1
options.scale = 1
options.auto_size = false
options.convert_path = windows_prompt? ? 'magick' : 'convert'

option_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} input-file output-file [options]"
  opts.separator ""
  opts.separator "Options:"

  opts.on('-p', '--spread SPREAD', Float, 'Spread of the DF in pixels (default: 8).') do |spread|
    options.spread = spread
  end

  opts.on('-q', '--quality QUALITY', Float, 'DF is created after scaling input by this factor (default: 1).') do |quality|
    options.quality = quality
  end

  opts.on('-s', '--scale SCALE', Float, 'Output is scaled by this factor after creating DF (default: 1).') do |scale|
    options.scale = scale
  end

  opts.on('-i', '--invert', 'Invert input image. Use when input contents is white.') do
    options.invert = true
  end

  opts.on('-a', '--auto-size', 'Extend or trim image to the size required by the DF.') do
    options.auto_size = true
  end

  opts.on('-c', '--convert-path PATH', String, 'Name or path of the ImageMagick "convert" tool.') do |path|
    options.convert_path = path
  end

  opts.on_tail('-h', '--help', 'Show this message.') do
    puts opts
    exit
  end
end

# parse the command line parameters or print the help message
if ARGV.count < 1
  puts option_parser
  exit
else
  begin
    option_parser.parse!
  rescue Exception => e
    log e.message
    exit
  end
end

# ARGV now contains all that's left after the options have been removed
if ARGV.count < 2
  log "You did not specify input and/or output file"
  exit
else
  input_file  = ARGV[0]
  output_file = ARGV[1]
end

spread = options.spread * options.quality / options.scale

command = "#{options.convert_path} #{input_file} "
command << "-negate " if options.invert
command << "-background white -alpha remove "
command << "-filter Jinc -resize #{options.quality * 100}\% -threshold 30% " unless options.quality == 1
command << "-bordercolor white -border #{spread}x#{spread} " if options.auto_size
command << "\\( +clone -negate -morphology Distance Euclidean:4,'#{spread}!' -level 50%,-50% \\) "
command << "-morphology Distance Euclidean:4,'#{spread}!' "
command << "-compose Plus -composite "
command << "-trim " if options.auto_size
command << "-resize #{options.scale / options.quality * 100}\% " unless options.scale * options.quality == 1
command << "-negate -alpha copy -channel RGB -fx '#fff' "
command << "PNG32:#{output_file}"

system_xp command

if $?.success?
  log "All done"
else
  log "I'm afraid there has been a problem"
end
