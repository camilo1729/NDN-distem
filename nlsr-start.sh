#!/bin/bash
echo $$ > /tmp/nlsr.pid
while [[ 1 ]]
do
    sleep $(( (10*$RANDOM)/32767))
    nlsr -f nlsr-`uname -n`.conf
done
