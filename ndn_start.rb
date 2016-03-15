
# Executing NDN daemons
topo = (YAML.load(File.open(topoFile,'r') {|f| f.read + "\n---\n"}) || {} )

Net::SSH::Multi.start do |session|


   session.group :vnodes do
     topo.keys.each { |vnode| session.use("root@#{vnode}-adm",{:paranoid => false})}
   end

   # test connection
   #

   [
     "mkdir -p /var/log/nlsr",
     "mkdir -p /var/lib/nlsr",
     "nohup nfd-start < /dev/null >./log 2>./log-err",
     "sleep 2"
  ].each { |x| session.with(:vnodes).exec! x }

end


puts "ssh"

topo.keys.each do |x|
  puts "On #{x}"
  system('ssh',"root@#{x}","echo -e '#{hosts[x]}' | dd of=/etc/hosts")
  system "ssh root@#{x} screen -d -m /root/nlsr-start.sh"
end
