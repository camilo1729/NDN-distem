#!/usr/bin/ruby

require 'distem'
require 'yaml'
require 'cute'
require 'ipaddr'
require 'net/scp'
load 'nlsrcGen.rb'

FSIMG="/home/cruizsanabria/distemIMGjessieNLSR3bis.tar.gz"

stateFile=ARGV[0]
topoFile=ARGV[1]
expState = (YAML.load(File.open(stateFile,'a+') {|f| f.read + "\n---\n"}) || {} )
topo = (YAML.load(File.open(topoFile,'r') {|f| f.read + "\n---\n"}) || {} )
expDescr = expState[:descr]
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
  i=0
  j=1
  #cl.vnetwork_create("netall","18.0.0.0/24")
  ip = IPAddr.new (expState['addr'])
  ip = ip.mask 16
  topo.each_pair do |name,h|
    if j < vNodesPerLessChargedPnodes + (i < nbrOfOverChargedPnodes ? 1 : 0)
    then j += 1
    else j=1; i += 1
    end
    puts name
    puts expState['nodes'][i]
    cl.vnode_create(name, { 'host' => expState['nodes'][i] },  sshkeys)
    cl.vfilesystem_create(name,  { 'image' => "file://#{FSIMG}" , :cow => true})
   # cl.viface_create(name, "all0", { 'vnetwork' => 'netall'})
    h['neighs'].each do |n|
      if n <= name
      then
        puts ip
        cl.vnetwork_create("#{n}-#{name}", "#{ip.to_s}/27")
        32.times { ip = ip.succ}
      else nil
      end
    end
  end

  topo.each_pair do |name,h|
    h['neighs'].each do |n|
      inf = n <= name
      res = cl.viface_create(name, "#{n}#{name}",
                             { 'vnetwork' => "#{ ((inf) ? n : name)}-#{ ((inf) ? name : n)}" })
      addr = res['address'].split('/').first
      hosts[n] << [addr,name]
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

sleep 2

# Testing connection
Net::SSH::Multi.start do |session|
   session.group :vnodes do
     topo.keys.each { |vnode| session.use("root@#{vnode}-adm",{:paranoid => false})}
   end
   puts session.with(:vnodes).exec "hostname"
end


# we need to transfert file using the admin network
topo.keys.each do |vnode|
  # setting admin address
  node_name = "#{vnode}-adm"
  Net::SCP.start(node_name,'root') do |scp|
    conf_file ="root/nlsr-#{vnode}.conf"
    puts "uploading #{File.basename(conf_file)} to node: #{node_name}"
    puts scp.upload! conf_file,File.basename(conf_file)
  end
end



# Cute::TakTuk.start(topo.keys,:connector => 'ssh -o StrictHostKeyChecking=no',:user => 'root') do |tak|

#   [
#     "'nohup nfd-start < /dev/null >>./log 2>>./log'",
#     "'mkdir -p /var/log/nlsr'",
#     "'mkdir -p /var/lib/nlsr'",
#     "'sh -c \"nohup nlsr -f nlsr-`uname -n`.conf -d\"'",
#   ].each { |x| prettyPrint(tak.exec!(x))}


# end
