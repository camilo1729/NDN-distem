#!/usr/bin/ruby
require 'distem'
require 'cute'
require 'net/scp'
load 'nlsrcGen-peer.rb'

NDNIMG="/home/cruizsanabria/jessie-ndn-lxc.tar.gz"
numpeers = 16
vnetwork = IPAddress::IPv4.new("10.144.0.0/18")

subnets = vnetwork.subnet(24)

dir_config = "nslr_config"
Dir.mkdir dir_config

vnodes = []
hosts = {}
machines = ["grisou-38","grisou-39","grisou-40","grisou-41","grisou-42","grisou-43","grisou-44","grisou-45","grisou-46","grisou-47","grisou-48","grisou-49","grisou-50","grisou-51",
           "grisou-6","grisou-7","grisou-8","grisou-9"]
Distem.client do |cl|


  numpeers.times do |x|

    cl.vnetwork_create("vnet#{x}", subnets[x].to_string, :network_type => 'vxlan')

    node1 = "n#{x}"
    node2 = "n#{x}-1"
    ips = subnets[x].map{ |ip| ip.to_s}
    cl.vnode_create(node1,
                  {
                   'host' => machines[x],
                   'vfilesystem' =>{'image' => NDNIMG,'cow' => true},
                   'vifaces' => [
                                 {'name' => 'if0', 'vnetwork' => "vnet#{x}", 'address' => ips[2]},
                                ]
                  })

    cl.vnode_create(node2,
                  {
                   'host' => machines[x],
                   'vfilesystem' =>{'image' => NDNIMG,'cow' => true},
                   'vifaces' => [
                                 {'name' => 'if0', 'vnetwork' => "vnet#{x}", 'address' => ips[3]},
                                ]
                  })

    vnodes+=[node1,node2]

    puts "Generating configuration files"
    node = {:name => node1,:site => "s#{x}",:router => "r#{x}", :ip => ips[2]}
    neighbor = {:name => node2,:site => "s#{x}-1",:router => "r#{x}-1", :ip => ips[3]}
    File.open("#{dir_config}/nlsr-#{node1}.conf",'w') {|f| f.write confGen(node,neighbor)}
    File.open("#{dir_config}/nlsr-#{node2}.conf",'w') {|f| f.write confGen(neighbor,node)}
    hosts[node1.to_sym] = ips[2]
    hosts[node2.to_sym] = ips[3]
    
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
File.open("hosts_file",'w') do |f|
  hosts.each{ |host, ip| f.puts("#{host}\t#{ip}")}
end


vnodes.each do |vnode|
  # setting admin address
  Net::SCP.start("#{vnode}-adm",'root') do |scp|
    conf_file ="#{dir_config}/nlsr-#{vnode}.conf"
    nlsr_start_file = "nlsr-start.sh"
    puts "uploading #{File.basename(conf_file)} to node: #{vnode}"
    puts scp.upload! conf_file,File.basename(conf_file)
    puts scp.upload! nlsr_start_file,File.basename(nlsr_start_file)
    puts scp.upload! "hosts_file","/etc/hosts"
  end
end


# saving host for /etch/hosts


File.open("machinefile.txt", 'w') do |f|
  hostnames.each { |vnode|  f.puts vnode}
end


end
