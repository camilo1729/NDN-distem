require 'yaml'

# Executing NDN daemons
topo = (YAML.load(File.open(topoFile,'r') {|f| f.read + "\n---\n"}) || {} )
hosts = YAML.load(File.open("hosts_helper.yaml",'r') )


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

# updating hosts file and starting nlsr

topo.keys.each do |vnode|
  Net::SSH.start("#{vnode}-adm", "root") do |ssh|
    puts "On #{x}"
    ssh.exec! "echo -e '#{hosts[x]}' | dd of=/etc/hosts"
    ssh.exec! "screen -d -m /root/nlsr-start.sh"
  end
end
