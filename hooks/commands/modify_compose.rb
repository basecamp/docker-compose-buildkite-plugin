require 'yaml'
require 'fileutils'

filename = ARGV[0]
service = ARGV[1]
image = ARGV[2]

if File.exist?(filename)
  FileUtils.cp filename, "#{filename}.orig"
  compose = YAML.load(File.read(ARGV[0]))
  compose['services'][service]['image'] = image
  IO.write(filename, compose.to_yaml)
end
