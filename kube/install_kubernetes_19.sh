#!/bin/bash

config(){
   systemctl stop firewalld && systemctl disable firewalld
   echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
   echo 1 > /proc/sys/net/bridge/bridge-nf-call-ip6tables
   sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config && setenforce 0
   swapoff -a
   yes | cp /etc/fstab /etc/fstab_bak
   cat /etc/fstab_bak |grep -v swap > /etc/fstab
  
   yes y | cp k8s.conf /etc/sysctl.d/
   modprobe br_netfilter
   sysctl -p /etc/sysctl.d/k8s.conf

   yes y | cp kubernetes.repo /etc/yum.repos.d/
}

remove_docker(){
   echo "removing docker's components"
   systemctl disable docker
   systemctl stop docker
   docker_components=($(yum list installed | grep docker))
   if [ ${#docker_components[@]} -gt 0 ]; then  # $n is still undefined!
      for component in "${docker_components[@]}"; do
          echo removing $docker_components
          yum -y remove $component
      done
   fi
}

remove_kube(){
   yes y | kubeadm reset
   systemctl disable kubectl
   systemctl stop kubectl
   echo "removing kubernetes' components"
   kube_components=($(yum list installed | grep kube))
   if [ ${#kube_components[@]} -gt 0 ]; then  # $n is still undefined!
      for component in "${kube_components[@]}"; do
         echo removing $kube_components
         yum -y remove $component
     done
  fi
}

install_kube(){
   yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
   yum install -y docker-ce-19.03.12-3.el7
   systemctl start docker && systemctl enable docker

   yum install -y kubelet-1.19.2 
   yum install -y kubeadm-1.19.2 
   yum install -y kubectl-1.19.2

   #启动kubelet服务
   systemctl enable kubelet && systemctl start kubelet
}

#for new host
install_collectl(){
  yes y | yum install epel-release -y
  yes y | yum -y install collectl
}
#for new host
install_java8(){
  yes y |yum install java-1.8.0-openjdk-devel
}


config
remove_docker
remove_kube
install_kube

#nodes need to be reboot so that docker can start normally.
