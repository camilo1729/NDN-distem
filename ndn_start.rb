require 'yaml'
require 'cute'

# Executing NDN daemon
topoFile=ARGV[0]

topo = (YAML.load(File.open(topoFile,'r') {|f| f.read + "\n---\n"}) || {} )
hosts = YAML.load(File.open("hosts_helper.yaml",'r') )

nodes = topo.keys

Cute::TakTuk.start(nodes, :user => 'root') do |tak|

  [
     "mkdir -p /var/log/nlsr",
     "mkdir -p /var/lib/nlsr",
     "nohup nfd-start < /dev/null >./log 2>./log-err",
     "sleep 2"
  ].each { |x| tak.exec! x }

end



sleep 10
# updating hosts file and starting nlsr

topo.keys.each do |vnode|
  Net::SSH.start("#{vnode}-adm", "root") do |ssh|
    puts "On #{vnode}"
    ssh.exec! "echo -e '#{hosts[vnode]}' | dd of=/etc/hosts"
    ssh.exec! "screen -d -m /root/nlsr-start.sh"
  end
end
