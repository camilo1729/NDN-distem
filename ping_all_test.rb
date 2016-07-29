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
