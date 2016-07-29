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
