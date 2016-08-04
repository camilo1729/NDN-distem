
require 'yaml'
require 'pry'

file = ARGV[0].delete(".txt")
size = file.split("-")[2][/\d+/]
data = YAML::load(File.read("#{file}.txt"))
results = {}

data.each do |k,v|
  raw_result = v[:stderr].split("\n")[0].split("\t")[1]
  min_sec = raw_result.split("m")
  real_time = min_sec[0].to_i*60 + min_sec[1].delete("s").to_f
  results[k.delete("-adm")] = real_time
end

File.open("#{file}-clean.txt",'w') do |f|
  f.puts "node,time,size"
  results.each{ |k,v| f.puts "#{k},#{v},#{size}"}
end
