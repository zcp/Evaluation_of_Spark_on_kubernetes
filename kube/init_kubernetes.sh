#!/bin/bash
#!/bin/bash

master_ip=192.168.10.4
master_hostname=k8s-master
time_server=k8s-master
#slave1_hostname=worker-6

#192.168.10.6  k8s-master myregistry.local
#192.168.110.6 k8s-master
worker1=192.168.10.11
worker2=192.168.10.12
worker3=192.168.10.13
worker4=192.168.10.14
worker5=192.168.10.15
worker6=192.168.10.16
store1=192.168.10.201
#192.168.10.202 store-2


slave1_hostname=thinkstation-e32-1
slave2_hostname=thinkstation-e32-2


nodes=($master_hostname $worker1 $worker2 $worker3 $worker4 $worker6)
node_num=${#nodes[@]}
range=`expr $node_num - 1`

password=123456
nodes_names=($master_hostname worker-1 worker-2 worker-3 worker-4 worker-6)
setLabels(){
   kubectl label nodes ${nodes_names[0]} role=master  --overwrite
   for i in $( eval echo {1..$range} ); do
       node_name=${nodes_names[$i]}
       echo $node_name
       #node shoulde be a name, instead of its ip
       kubectl label nodes $node_name role=worker  --overwrite
   done
}

mask_ssh_confirm(){
   #for master
   sudo bash -c 'echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config'
   #for other hosts.
   for i in $( eval echo {1..$range} ); do
       node=${nodes[$i]}
       sudo ssh $node "bash -c 'echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config'"
   done
}


activateDocker(){
   for i in $( eval echo {0..$range} ); do
       node=${nodes[$i]}
       port=${nodes_ports[$i]}
       yes y | sshpass -p $password sudo ssh $node -tt "sudo groupadd docker"
       yes y | sshpass -p $password sudo ssh $node -tt "sudo systemctl start docker.service"
       yes y | sshpass -p $password sudo ssh $node -tt "sudo systemctl enable docker.service"
       #ssh $node "yes y | sudo apt-get install sysstat"
   done
}

activateMaster(){
    sudo swapoff -a
    rm -rf /var/lib/cni/flannel/* && rm -rf /var/lib/cni/networks/cbr0/* && ip link delete cni0  
    rm -rf /var/lib/cni/networks/cni0/*
    yes y | kubeadm reset
    systemctl restart kubelet

    kubeadm init --apiserver-advertise-address=$master_ip --image-repository myregistry.local:5000 --kubernetes-version v1.19.2 --pod-network-cidr=10.244.0.0/16

    #kubeadm init --apiserver-advertise-address=$master_ip --image-repository registry.aliyuncs.com/google_containers --kubernetes-version v1.19.2 --pod-network-cidr=10.244.0.0/16
    sudo mkdir -p $HOME/.kube
    yes y | sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    export kubever=$(kubectl version | base64 | tr -d '\n')
    kubectl apply -f kube-flannel.yml
    #sudo kubectl create -f kube-flannel_eth0.yml 
    #install metrics-server
    cd metrics-server;
    kubectl create -f deploy/1.8+/
    cd ..
}

sync_time(){
     for i in $( eval echo {1..$range} ); do
         node=${nodes[$i]}
         sshpass -p $password ssh $node "ntpdate -u $time_server"
     done
}

addNodes(){
     join_token=$(kubeadm token create --print-join-command)
     #skip master nodes
     for i in $( eval echo {1..$range} ); do
         node=${nodes[$i]}
         yes y | sshpass -p $password ssh $node "rm -rf /var/lib/cni/flannel/* && rm -rf /var/lib/cni/networks/cbr0/* && ip link delete cni0"
         yes y | sshpass -p $password ssh $node "rm -rf /var/lib/cni/networks/cni0/*"
         yes y | sshpass -p $password ssh $node  "yes y | kubeadm reset; swapoff -a; $join_token"
     done
}

setTimeZone(){
     for i in $( eval echo {0..$range} ); do
        node=${nodes[$i]}
        yes y | sshpass -p $password ssh $node "sudo timedatectl set-timezone America/New_York"
     done
}

#We have to run the following two commands first to run spark on kubernetes
createSparkAccount(){
   kubectl create serviceaccount spark
   kubectl create clusterrolebinding spark-role --clusterrole=edit --serviceaccount=default:spark --namespace=default
}

conf_network(){
     gateway_ip=192.168.10.6
     for i in $( eval echo {0..$range} ); do
         node=${nodes[$i]}
         sshpass -p $password ssh $node "route add default gateway $gateway_ip eth0"
     done    
}

install_collectl(){
     for i in $( eval echo {0..$range} ); do
         node=${nodes[$i]}
         sshpass -p $password ssh $node "yum install epel-release -y; yum install collectl -y"
     done   
}
#mask_ssh_confirm

activateDocker
activateMaster
setTimeZone
sync_time
addNodes
createSparkAccount

setLabels

#install_numpy
#conf_network
#install_collectl
