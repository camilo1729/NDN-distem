#!/usr/bin/ruby
require 'distem'

NDNIMG="/home/cruizsanabria/jessie-ndn-lxc.tar.gz"


numpeers = 16
vnetwork = IPAddress::IPv4.new("10.144.0.0/18")

subnets = vnetwork.subnet(24)
Distem.client { |cl|

  vnodes = []
  numpeers.times do |x|

    cl.vnetwork_create('vnet#{x}', subnets[x].to_string, :network_type => 'vxlan')

    ips = subnets[x].map{ |ip| ip.to_s}
    cl.vnode_create('n#{x}',
                  {
#                   'host' => machine,
                   'vfilesystem' =>{'image' => NDNIMG,'cow' => true},
                   'vifaces' => [
                                 {'name' => 'if0', 'vnetwork' => 'vnet#{x}', 'address' => ips[2]},
                                ]
                  })

    cl.vnode_create('n#{x}-1',
                  {
 #                   'host' => machine,
                   'vfilesystem' =>{'image' => NDNIMG,'cow' => true},
                   'vifaces' => [
                                 {'name' => 'if0', 'vnetwork' => 'vnet#{x}', 'address' => ips[3]},
                                ]
                  })

    vnodes+=["n#{x}","n#{x}-1"]
  end

  puts "Starting vnodes..."
  cl.vnodes_start(nodes)
  puts "Waiting for vnodes to be here..."
  sleep(30)
  ret = cl.wait_vnodes({'timeout' => 1200, 'port' => 22})
  if ret
    puts "Setting global /etc/hosts"
    cl.set_global_etchosts
  else
    puts "vnodes are unreachable"
  end
}
