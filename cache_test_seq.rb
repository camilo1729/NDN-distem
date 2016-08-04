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
  file_size = size_in_MB*1000000
  ssh.exec! "yes | tr \\n x | head -c #{file_size} > test_file.txt"
  sss.exec! "echo ' ndnputchunks -f 100000 /ndn/nodeAnnounce0x0x0/#{FILE_TEST} < test_file.txt' > script.sh"
  ssh.exec! "screen -d -m bash script.sh"
end


# waiting for the file to be available


sleep 100

nodes_to_test = ["n0-0-1","n0-0-2","n0-0-3","n1-0-0","n1-0-1","n1-0-2","n1-0-3","n2-0-0","n2-0-1","n2-0-2","n2-0-3"]

puts "Starting to download file on all nodes"

nodes_to_test.each do |vnode|

  Net::SSH.start("#{vnode}-adm", "root") do |ssh|
    puts "Get on node: #{vnode}"
  # we setup latencies of 10ms so we have to augment the -l parameter
    puts ssh.exec "time ndncatchunks  -l 100 -d iterative -p 20 /ndn/nodeAnnounce0x0x0/#{FILE_TEST} > download"
#  end
  end
end

puts "Killing ndnputchunks"
Net::SSH.start("n0-0-0-adm", "root") do |ssh|
  puts "On n0-0-0"
  ssh.exec! "killall ndnputchunks"
end
