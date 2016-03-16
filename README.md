# NDN-distem

* NDN experiments over distem

This is the procedure to follow in order to repeat the experiment in Grid'5000.

First reserving the nodes:

oarsub -t deploy -t destructive -l slash_22=1+nodes=5,walltime=5:00:00 "sleep 1d"

We need five nodes for deploying the entirerly infrastructure otherwise we have problems when starting
the daemons.
Deploying environment:

kadeploy3 -f $OAR_NODEFILE -e jessie-x64-nfs -k

Executing debootstrap with btrfs options:

ruby examples/distem-bootstrap -g --debian-version jessie -f /tmp/machinefile --enable-admin-network --btrfs-format /dev/sda5

we have to install gems: ruby-cute and net-scp

Clonning the repository in the coordinator node:

git clone https://github.com/camilo1729/NDN-distem.git

create the file exp.state.yaml with the names of all physical machines that are running Ditem

ruby ndn_topo.rb exp.state.yaml fai1.yaml

And then start the NDN daemons:

ruby ndn_start.rb fai1.yaml
