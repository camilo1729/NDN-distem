require 'yaml'

output = ARGV[0]
leaves = ARGV[1].to_i
medium = ARGV[2].to_i-1
central = ARGV[3].to_i-1

#topo = file.clone

puts central
topo = {}
# binding.pry
(0..central).each do |c|
#  core = {
  neighs = (0..central).map{ |v| "n#{v}" if v != c}.compact
  topo["n#{c}"] = {"router"=>"/router", "site"=>"/s-#{c}", "net"=>"/n-#{c}", "neighs"=>neighs, "announce"=>["/netAnnounce#{c}"]}
  (0..medium).each do |m|
    parent ="n#{c}-#{m}"
    topo["n#{c}"]["neighs"].push(parent)
    topo[parent] = {"router"=>"/siterouter", "site"=>"/s-#{c}-#{m}", "net"=>"/n-#{c}", "neighs"=>[], "announce"=>["/netAnnounce#{c}x#{m}"]}
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
