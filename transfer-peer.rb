require 'yaml'
require 'cute'

# put create data packages on one node


nodes = []


File.open("machinefile.txt", "r").each_line do |line|
  nodes.push(line.chop)
end




# putting a file available
size_in_MB = ARGV[0].to_i
FILE_TEST = "file#{size_in_MB}"

results = {}

num_nodes = 16
Net::SSH::Multi.start do |session|
  session.group :source do
    num_nodes.times.each{ |x| session.use("n#{x}-adm",{:user => "root",:paranoid => false})}
  end

  session.group :client do
    num_nodes.times.each{ |x| session.use("n#{x}-1-adm",{:user => "root",:paranoid => false})}
  end

  file_size = size_in_MB*1000000
  session.with(:source).exec! "yes | tr \\n x | head -c #{file_size} > test_file.txt"
  session.with(:source).exec! "echo ' ndnputchunks -f 100000 /ndn/n#{x}/#{FILE_TEST} < test_file.txt' > script.sh"
  session.with(:source).exec! "screen -d -m bash script.sh"

  sleep size_in_MB
  puts "Starting to download file on all nodes"
  # we setup latencies of 10ms so we have to augment the -l parameter
  results = session.with(:client).exec! "time ndncatchunks  -l 100 -d iterative -p 20 /ndn/n#{x}/#{FILE_TEST} > download"

  sleep 10
  puts "killing all instances of nndputchunks"
  session.with(:source).exec! "killall ndnputchunks"
#  end
end


File.open("results_cache#{size_in_MB}MB",'w') do |f|
  f.puts(results.to_yaml)
end
