FROM debian:jessie
RUN apt-get -y update && apt-get install -y g++ make taktuk openssh-server libc6-dev-i386 devscripts build-essential git pkg-config
RUN apt-get install -y wget libsqlite3-dev libcrypto++-dev libboost-all-dev
RUN apt-get install -y libpcap-dev libcap2-bin screen liblog4cxx10-dev libprotobuf-dev protobuf-compiler libssl-dev

# Install NDN

RUN git clone https://github.com/named-data/ndn-cxx && cd ndn-cxx && ./waf configure && ./waf && ./waf install

# Install NFD

RUN git clone --recursive https://github.com/named-data/NFD && cd NFD && ./waf configure && ./waf && ./waf install
RUN  cp /usr/local/etc/ndn/nfd.conf.sample /usr/local/etc/ndn/nfd.conf

# Install NDN_tools

RUN git clone https://github.com/named-data/ndn-tools && cd ndn-tools && ./waf configure && ./waf && ./waf install

# Install NLSR

RUN git clone https://github.com/named-data/NLSR.git && cd NLSR && ./waf configure && ./waf && ./waf install
