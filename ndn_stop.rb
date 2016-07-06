require 'yaml'
require 'cute'

# Executing NDN daemon
topoFile=ARGV[0]

topo = (YAML.load(File.open(topoFile,'r') {|f| f.read + "\n---\n"}) || {} )
hosts = YAML.load(File.open("hosts_helper.yaml",'r') )


Net::SSH::Multi.start do |session|


   session.group :vnodes do
     topo.keys.each { |vnode| session.use("root@#{vnode}-adm",{:paranoid => false})}
   end

   # test connection
   #

   [
     "killall nfd",
     "killall screen"
  ].each { |x| session.with(:vnodes).exec! x }



end

