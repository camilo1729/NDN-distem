require 'yaml'
require 'cute'
require 'net/scp'
# put create data packages on one node


vnodes = []


File.open("machinefile.txt", "r").each_line do |line|
  vnodes.push(line.chop)
end


# putting a file available

results = {}

num_nodes = 16

puts "Transfering ndnperf"

vnodes.each do |vnode|
  # setting admin address
  Net::SCP.start(vnode,'root') do |scp|
    files = ["/root/ndnperf/c++/server/blockingconcurrentqueue.h",
             "/root/ndnperf/c++/server/concurrentqueue.h",
             "/root/ndnperf/c++/server/gen.cpp",
             "/root/ndnperf/c++/server/server.cpp",
             "/root/ndnperf/c++/client/client.cpp"]

    files.each{ |file| puts scp.upload! file,File.basename(file)}

  end
end



Net::SSH::Multi.start do |session|
  session.group :source do
    num_nodes.times.each{ |x| session.use("n#{x}-adm",{:user => "root",:paranoid => false})}
  end

  session.group :client do
    num_nodes.times.each{ |x| session.use("n#{x}-1-adm",{:user => "root",:paranoid => false})}
  end


  session.with(:source).exec! "g++ -o ndnperfserver server.cpp -std=c++11 -O2 -lndn-cxx -lcryptopp -lboost_system -lboost_filesystem -lpthread"
  session.with(:source).exec! "screen -d -m /root/ndnperfserver -p /ndn/$(hostname)/perf -t 1"

  puts "Waiting"
  sleep 10
  puts "Starting ndnperf"
  # we setup latencies of 10ms so we have to augment the -l parameter
  session.with(:client).exec! "g++ -o ndnperf client.cpp -std=c++11 -O2 -lndn-cxx -lboost_system -lpthread"
  results = session.with(:client).exec! "nohup /root/ndnperf -p /ndn/$(hostname | tr \"-\" \"\n\" | head -n 1)/perf > results-$(hostname).txt &"
  sleep 100
  session.with(:client).exec! "killall ndnperf"
  puts "killing all instances of nndputchunks"
  session.with(:source).exec! "killall ndnperfserver"
#  end
end


File.open("results_ndnperf",'w') do |f|
  f.puts(results.to_yaml)
end
