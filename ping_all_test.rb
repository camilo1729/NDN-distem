require 'yaml'
require 'cute'
require 'distem'
# put create data packages on one node


nodes = []


File.open("machinefile.txt", "r").each_line do |line|
  nodes.push(line.chop)
end


#nodes.delete("uiuc")

# Initializing ping server
Distem.client do |cl|

  nodes.each do |node_to_kill|

    `ruby ndn_stop.rb ndn_testbed_topo.yaml`
    sleep 2
    `ruby ndn_start.rb  ndn_testbed_topo.yaml`
    sleep 10
    `ruby initialize_ping_server.rb`

  # checking that all the servers have been initiazlied

    num_server = `ps aux | grep ndnping | wc -l `.chop

    puts "Number of ping servers running #{num_server}"

    if num_server != "46"
      puts "problemm initializing exiting"
      exit
    end

    results = {}
    Net::SSH::Multi.start do |session|

      session.group :vnodes do
        nodes.each{ |vnode| session.use("#{vnode}-adm",{:user => "root",:paranoid => false})}
      end

      nodes.each do |node|
        session.with(:vnodes).exec! "nohup ndnping -c 200 /ndn/nodeAnnounce#{node} > #{node}.txt &"
      end

    end


    puts "Killing node: #{node_to_kill}"
    sleep 20
    cl.vnode_stop(node_to_kill)
    sleep 200


    temp_nodes = nodes.clone
    temp_nodes.delete(node_to_kill)

    `mkdir -p results_#{node_to_kill}`

    temp_nodes.each do |vnode|

      dir_node = "results_#{node_to_kill}/#{vnode}"
      `mkdir -p #{dir_node}`
      `scp #{vnode}-adm:~/*.txt #{dir_node}/`

      Net::SSH.start("#{vnode}-adm", "root") do |ssh|
        puts "Deleting files On #{vnode}"
        ssh.exec "rm *.txt"
      end

    end

    num_server = `ps aux | grep ndnping | wc -l `.chop

    puts "Number of ping servers running #{num_server}"

    if num_server != "46"
      puts "problemm number of ping server results are probably false repeat the measure with node: #{node_to_kill}"
      exit
    end


    puts "Restarting node: #{node_to_kill}"
    cl.vnode_start(node_to_kill)
    sleep 10
  end
end
