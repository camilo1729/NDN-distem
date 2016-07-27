require 'yaml'
require 'cute'

# put create data packages on one node


nodes = []


File.open("machinefile.txt", "r").each_line do |line|
  nodes.push(line.chop)
end


#nodes.delete("uiuc")

# putting a file available

FILE_TEST = "bigfile"

Net::SSH.start("n0-0-0-adm", "root") do |ssh|
  puts "On n0-0-0"
  ## 20 MB file
  ssh.exec! "yes | tr \\n x | head -c 20000000 > test_file.txt"
  ssh.exec! "echo ' ndnputchunks -f 100000 /ndn/nodeAnnounce0x0x0/#{FILE_TEST} < test_file.txt' > script.sh"
  ssh.exec! "screen -d -m bash script.sh"
end


# waiting for the file to be available

sleep 100

results = {}
Net::SSH::Multi.start do |session|
  session.group :producer do
    nodes.each{ |vnode| session.use("#{vnode}-adm",{:user => "root",:paranoid => false})}
  end

#  nodes.each do |node|
#  results[node] = session.exec! "ndnping -c 100 /ndn/nodeAnnounce#{nodes[2]}"
  # we setup latencies of 10ms so we have to augment the -l parameter
  results = session.exec! "time ndncatchunks  -l 100 -d iterative /ndn/nodeAnnounce0x0x0/#{FILE_TEST} > download"
#  end
end


File.open("results_ping",'w') do |f|
  f.puts(results.to_yaml)
end
