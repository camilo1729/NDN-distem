require 'yaml'
require 'cute'

# put create data packages on one node

Net::SSH::Multi.start do |session|
  session.group :producer do
    session.use("root@n0-0-adm",{:paranoid => false})
  end

  session.group :consumer do
    session.use("root@n1-0-adm",{:paranoid => false})
  end
  session.group :consumer2 do
    session.use("root@n2-0-adm",{:paranoid => false})
  end

  50.times.each do |x|
    puts session.with(:producer).exec! "yes | tr \\n x | head -c 8000 | ndnpoke -f -x 100000 /ndn/nodeAnnounce0x0/packeta#{x} &"
    puts "Getting with command: time ndnpeek -pf /ndn/nodeAnnounce0x0/packeta#{x} > test#{x}.txt "
    puts session.with(:consumer).exec! "time ndnpeek -pf /ndn/nodeAnnounce0x0/packeta#{x} > test#{x}.txt "
    puts session.with(:consumer2).exec! "time ndnpeek -pf /ndn/nodeAnnounce0x0/packeta#{x} > test#{x}.txt "

  end
end
