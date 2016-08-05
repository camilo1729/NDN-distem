require 'pry'
file = ARGV[0].delete(".txt")
size = file.split("-")[2][/\d+/]
temp = File.readlines("#{file}.txt")
data = temp[2..temp.length]

data_clean = data.map{ |p| p if (p["Get"] or p["real"])}.compact

results = {}
(0..data_clean.length-1).step(2) do |count|
  node = data_clean[count].split(":")[1].strip
  raw_result = data_clean[count+1].split("\t")[1]
  min_sec = raw_result.split("m")
  real_time = min_sec[0].to_i*60 + min_sec[1].delete("s").to_f
  results[node] = real_time
end

File.open("#{file}-clean.txt",'w') do |f|
  f.puts "node,time,size"
  results.each{ |k,v| f.puts "#{k},#{v},#{size}"}
end
