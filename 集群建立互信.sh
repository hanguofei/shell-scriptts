#!/bin/sh

## 1 delete .ssh directory
UserName="root"
rm -rf ~/.ssh
ssh-keygen -t rsa
ssh-keygen -t dsa

startnode=7
endnode=7

for ((i=${startnode}; i<=${endnode}; i++));
do
        ssh  $UserName@node$i 'rm -rf ~/.ssh; ssh-keygen -t rsa -f ~/.ssh/id_rsa -P "";exit '     
        ssh $UserName Node$i 'rm -rf ~/.ssh;ssh-keygen -t rsa -f ~/.ssh/id_rsa -P "";exit'
done;

# 2 copy public keys to one file
#ssh $UserName@node1
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys 
for ((i=${startnode}; i<=${endnode}; i++));
do
        ssh $UserName@node$i cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys    
        ssh $UserName@node$i cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys
done;

# 3 Dispath authorized_keys to other machines and change file property
chmod 600 ~/.ssh/authorized_keys
for ((i=${startnode};i<=${endnode};i++));
do
        scp ~/.ssh/authorized_keys $UserName@node$i:~/.ssh/
        ssh $UserName@node$i 'chmod 600 ~/.ssh/authorized_keys'
done;
