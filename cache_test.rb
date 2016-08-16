require 'yaml'
require 'cute'

# put create data packages on one node


nodes = []


File.open("machinefile.txt", "r").each_line do |line|
  nodes.push(line.chop)
end


#nodes.delete("uiuc")

# putting a file available
size_in_MB = 20
FILE_TEST = "file#{size_in_MB}"

Net::SSH.start("n0-0-0-adm", "root") do |ssh|
  puts "On n0-0-0"
  ## 20 MB file
  file_size = size_in_MB*1000000
  ssh.exec! "yes | tr \\n x | head -c #{file_size} > test_file.txt"
  ssh.exec! "echo ' ndnputchunks -f 100000 /ndn/nodeAnnounce0x0x0/#{FILE_TEST} < test_file.txt' > script.sh"
  ssh.exec! "screen -d -m bash script.sh"
end


# waiting for the file to be available
# value for 600MB file, to change for smaller files
sleep 400

puts "Starting to download file on all nodes"
results = {}
Net::SSH::Multi.start do |session|
  session.group :producer do
    nodes.each{ |vnode| session.use("#{vnode}-adm",{:user => "root",:paranoid => false})}
  end

  # we setup latencies of 10ms so we have to augment the -l parameter
  results = session.exec! "time ndncatchunks  -l 100 -d iterative -p 20 /ndn/nodeAnnounce0x0x0/#{FILE_TEST} > download"
#  end
end


puts "Killing ndnputchunks"
Net::SSH.start("n0-0-0-adm", "root") do |ssh|
  puts "On n0-0-0"
  ssh.exec! "killall ndnputchunks"
end


File.open("results_cache#{size_in_MB}MB",'w') do |f|
  f.puts(results.to_yaml)
end
