require 'yaml'
require 'cute'

# put create data packages on one node


nodes = []


File.open("machinefile.txt", "r").each_line do |line|
  nodes.push(line.chop)
end


#nodes.delete("uiuc")

# Initializing ping server

nodes.each do |vnode|
  Net::SSH.start("#{vnode}-adm", "root") do |ssh|
    puts "On #{vnode}"
    ssh.exec "screen -d -m ndnpingserver /ndn/nodeAnnounce#{vnode}"

  end

end


results = {}
Net::SSH::Multi.start do |session|
  session.group :producer do
    nodes.each{ |vnode| session.use("#{vnode}-adm",{:user => "root",:paranoid => false})}
  end

#  nodes.each do |node|
#  results[node] = session.exec! "ndnping -c 100 /ndn/nodeAnnounce#{nodes[2]}"
  results = session.exec! "ndnping -c 100 /ndn/nodeAnnounce#{nodes[2]}"
#  end
end


File.open("results_ping",'w') do |f|
  f.puts(results.to_yaml)
end
