require 'yaml'
require 'cute'

# put create data packages on one node


nodes = []


File.open("machine_file", "r").each_line do |line|
  nodes.push(line.chop)
end

# Initializing ping server
nodes.each do |vnode|
  Net::SSH.start("#{vnode}-adm", "root") do |ssh|
    puts "On #{vnode}"
    ssh.exec! "nohup ndnpingserver /ndn/netAnnounce#{vnode}"
  end

end

Net::SSH::Multi.start do |session|
  session.group :producer do
    nodes.each{ |node| session.use(node,{:user => "root",:paranoid => false})}
  end


  results = session.exec! "ndnping -c 100 /ndn/netAnnounce#{nodes.first}"

end


File.open("results_ping",'w') do |f|
  f.puts(results.to_yaml)
end
