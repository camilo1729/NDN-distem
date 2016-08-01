require 'yaml'
require 'cute'

# put create data packages on one node


nodes = []


File.open("machinefile.txt", "r").each_line do |line|
  nodes.push(line.chop)
end


#nodes.delete("uiuc")

# Initializing ping server


results = {}
Net::SSH::Multi.start do |session|

  session.group :vnodes do
    nodes.each{ |vnode| session.use("#{vnode}-adm",{:user => "root",:paranoid => false})}
  end

  nodes.each do |node|
    session.with(:vnodes).exec! "nohup ndnping -c 100 /ndn/nodeAnnounce#{node} > #{node}.txt &"
  end

end


sleep 200

node_delete = "uiuc"
nodes.delete(node_delete)

`mkdir -p results_#{node_delete}`

nodes.each do |vnode|

  dir_node = "results_#{node_delete}/#{vnode}"
  `mkdir -p #{dir_node}`
  `scp #{vnode}-adm:~/*.txt #{dir_node}/`

  Net::SSH.start("#{vnode}-adm", "root") do |ssh|
    puts "Deleting files On #{vnode}"
    ssh.exec "rm *.txt"
  end

end
