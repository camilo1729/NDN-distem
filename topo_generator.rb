require 'yaml'
require 'pry'


output = ARGV[0]
leaves = ARGV[1].to_i

file = YAML.load(File.read("fai3.yaml"))
topo = file.clone


(0..4).each do |c|
  (0..1).each do |m|
    parent ="n#{c}-#{m}"
    site ="#{c}-#{m}"
    result = {}
    topo[parent]["neighs"] = ["n#{c}"]
    leaves.times do |leave|
      node = "n#{c}-#{m}-#{leave}"
      topo[parent]["neighs"].push(node)
      topo[node] = {"router"=>"/r-#{leave}", "site"=>"/s-#{site}", "net"=>"/n-#{c}", "neighs"=>[parent], "announce"=>["/nodeAnnounce#{c}x#{m}x#{leave}"]}
    end

  end
end

File.open(output,'w') { |f| f.write topo.to_yaml}
