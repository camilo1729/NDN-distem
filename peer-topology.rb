#!/usr/bin/ruby
require 'distem'
require 'cute'
load 'nlsrcGen-peer.rb'

NDNIMG="/home/cruizsanabria/jessie-ndn-lxc.tar.gz"
numpeers = 16
vnetwork = IPAddress::IPv4.new("10.144.0.0/18")

subnets = vnetwork.subnet(24)

dir_config = "nslr_config"
Dir.mkdir dir_config

vnodes = []
Distem.client do |cl|


  numpeers.times do |x|

    cl.vnetwork_create("vnet#{x}", subnets[x].to_string, :network_type => 'vxlan')

    node1 = "n#{x}"
    node2 = "n#{x}-1"
    ips = subnets[x].map{ |ip| ip.to_s}
    cl.vnode_create(node1,
                  {
#                   'host' => machine,
                   'vfilesystem' =>{'image' => NDNIMG,'cow' => true},
                   'vifaces' => [
                                 {'name' => 'if0', 'vnetwork' => "vnet#{x}", 'address' => ips[2]},
                                ]
                  })

    cl.vnode_create(node2,
                  {
 #                   'host' => machine,
                   'vfilesystem' =>{'image' => NDNIMG,'cow' => true},
                   'vifaces' => [
                                 {'name' => 'if0', 'vnetwork' => "vnet#{x}", 'address' => ips[3]},
                                ]
                  })

    vnodes+=[node1,node2]

    puts "Generating configuration files"
    node = {:site => "s#{x}",:router => "r#{x}", :ip => ips[2]}
    neighbor = {:site => "s#{x}-1",:router => "r#{x}-1", :ip => ips[3]}
    File.open("#{dir_config}/nlsr-#{node1}.conf",'w') {|f| f.write confGen(node,neighbor)}
    File.open("#{dir_config}/nlsr-#{node2}.conf",'w') {|f| f.write confGen(neighbor,node)}

  end


  puts "Starting vnodes..."
  cl.vnodes_start(vnodes)
  puts "Waiting for vnodes to be here..."
  sleep(30)
  ret = cl.wait_vnodes({'timeout' => 1200, 'port' => 22})
  if ret
    puts "Setting global /etc/hosts"
    cl.set_global_etchosts
  else
    puts "vnodes are unreachable"
  end

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

hostnames = vnodes.map{ |m| "#{m}-adm"}

# Testing connection
Net::SSH::Multi.start(:on_error => handler) do |session|
   session.group :vnodes do
     hostnames.each { |vnode| session.use("root@#{vnode}",{:paranoid => false})}
   end
   puts session.with(:vnodes).exec "hostname"
   # updating library path
   puts session.with(:vnodes).exec "ldconfig"
end


# we need to transfert file using the admin network
hostnames.each do |vnode|
  # setting admin address
  Net::SCP.start(vnode,'root') do |scp|
    conf_file ="root/nlsr-#{vnode}.conf"
    nlsr_start_file = "root/nlsr-start.sh"
    puts "uploading #{File.basename(conf_file)} to node: #{vnode}"
    puts scp.upload! conf_file,File.basename(conf_file)
    puts scp.upload! nlsr_start_file,File.basename(nlsr_start_file)
  end
end


# saving host for /etch/hosts

File.open("hosts_helper.yaml",'w') do |f|
  f.puts(hosts.to_yaml)
end

File.open("machinefile.txt", 'w') do |f|
  hostnames.each { |vnode|  f.puts vnode}
end


end
