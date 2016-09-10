require 'yaml'

expe_data = {}

expe_data["addr"] = ARGV[1]


nodes = File.readlines(ARGV[0]).map{ |m| m.chop}
expe_data["nodes"] = nodes
expe_data["descr"] = {"pnodes" => nodes.length}


output = ARGV[2]
File.open(output,'w') { |f| f.write expe_data.to_yaml}
