#!/usr/bin/ruby

require 'distem'
require 'yaml'
require 'cute'
require 'ipaddress'

require 'net/scp'
load 'nlsrcGen.rb'

FSIMG="/home/cruizsanabria/jessie-ndn-lxc.tar.gz"

stateFile=ARGV[0]
topoFile=ARGV[1]
expState = (YAML.load(File.open(stateFile,'a+') {|f| f.read + "\n---\n"}) || {} )
topo = (YAML.load(File.open(topoFile,'r') {|f| f.read + "\n---\n"}) || {} )
expDescr = expState['descr']
#expDescr = {'pnodes' => 1}
#expState = { 'nodes' => ['graphene-6']}
vnodesNbr = topo.length

hosts = {}

# Read SSH keys
private_key = IO.readlines('/root/.ssh/id_rsa').join
public_key = IO.readlines('/root/.ssh/id_rsa.pub').join
sshkeys = {
  'private' => private_key,
  'public' => public_key
}

system 'mkdir', '-p', 'root'
system 'rm root/nlsr-*.conf'
system 'cp nlsr-start.sh root/nlsr-start.sh'

topo.each_pair do |name,hash|
  File.open("root/nlsr-#{name}.conf",'w') {|f| f.write confGen(hash,topo)}
end

topo.keys.each do |name|
  hosts[name] = [["127.0.0.1",name],["::1",name]]
end


Distem.client do |cl|
  puts 'Creating virtual nodes'
  nbrOfOverChargedPnodes = vnodesNbr.modulo(expDescr['pnodes'])
  vNodesPerLessChargedPnodes = vnodesNbr/expDescr['pnodes']
  count = 0
  #cl.vnetwork_create("netall","18.0.0.0/24")
  net = IPAddress::IPv4.new(expState['addr'])
  iplist = net.map{ |ip| ip.to_s }
  cont_ip = 1
  topo.each_pair do |name,h|
    pnode = expState['nodes'][count.modulo(num_ponodes)]
    count+=1
    puts name
    puts pnode
    cl.vnode_create(name, { 'host' => pnode },  sshkeys)
    cl.vfilesystem_create(name,  { 'image' => "file://#{FSIMG}" , :cow => true})
   # cl.viface_create(name, "all0", { 'vnetwork' => 'netall'})
    h['neighs'].each do |n|
      n_name = n.is_a?(Hash)? n.keys.first : n
      if n_name <= name
      then
        ip = iplist[cont_ip]
        puts ip
        cl.vnetwork_create("#{n_name}-#{name}", "#{ip.to_s}/27")
        cont_ip+=32
      else nil
      end
    end
  end

  topo.each_pair do |name,h|
    h['neighs'].each do |n|
      n_name = n.is_a?(Hash)? n.keys.first : n
      inf = n_name <= name
      res = cl.viface_create(name, "#{n_name}#{name}",
                             { 'vnetwork' => "#{ ((inf) ? n_name : name)}-#{ ((inf) ? name : n_name)}",
                              'output' =>{"latency" =>{"delay" => "10ms"} } })
      addr = res['address'].split('/').first
      hosts[n_name] << [addr,name]
    end
  end

  cl.vnodes_start(topo.keys)
  cl.set_global_etchosts
end

topo.keys.each do |name|
  hosts[name] = hosts[name].reduce("LTD generated hosts file\n") { |acc,entry|  acc + "#{entry[0]}    #{entry[1]}\n"}
end

# system %Q(cp nlsr-*.conf /tmp/distem/rootfs-shared/*/root/)
# system %Q(tar -cz nlsr-*.conf | ./kascade -S 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' -D taktuk -i - -N #{expState['nodes'].reduce { |acc,x| "#{acc},#{x}" } } -O 'tar -xzC /tmp/distem/rootfs-shared/*/root/')


puts "taktuk"
# p expState['vnodesName']

handler = Proc.new do |server|

  server[:connection_attempts] ||= 0
  if server[:connection_attempts] < 40
    server[:connection_attempts] += 1
    puts "Retrying connection"
    sleep 5
    throw :go, :retry
  else
    throw :go, :raise
  end
end


# Testing connection
Net::SSH::Multi.start(:on_error => handler) do |session|
   session.group :vnodes do
     topo.keys.each { |vnode| session.use("root@#{vnode}-adm",{:paranoid => false})}
   end
   puts session.with(:vnodes).exec "hostname"
   # updating library path
   puts session.with(:vnodes).exec "ldconfig"
end


# we need to transfert file using the admin network
topo.keys.each do |vnode|
  # setting admin address
  node_name = "#{vnode}-adm"
  Net::SCP.start(node_name,'root') do |scp|
    conf_file ="root/nlsr-#{vnode}.conf"
    nlsr_start_file = "root/nlsr-start.sh"
    puts "uploading #{File.basename(conf_file)} to node: #{node_name}"
    puts scp.upload! conf_file,File.basename(conf_file)
    puts scp.upload! nlsr_start_file,File.basename(nlsr_start_file)
  end
end


# saving host for /etch/hosts

File.open("hosts_helper.yaml",'w') do |f|
  f.puts(hosts.to_yaml)
end

File.open("machinefile.txt", 'w') do |f|
  topo.keys.each { |vnode|  f.puts vnode}
end
